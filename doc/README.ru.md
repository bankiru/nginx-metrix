Nginx Metrix
============
[![Travis CI Build Status](https://travis-ci.org/bankiru/nginx-metrix.svg?branch=1.0-dev)](https://travis-ci.org/bankiru/nginx-metrix)
[![Appveyor Build Status](https://ci.appveyor.com/api/projects/status/s3hy8fq32869o375/branch/1.0-dev?svg=true)](https://ci.appveyor.com/project/ekho/nginx-metrix/branch/1.0-dev)
[![Coverage Status](https://coveralls.io/repos/github/bankiru/nginx-metrix/badge.svg?branch=1.0-dev)](https://coveralls.io/github/bankiru/nginx-metrix?branch=1.0-dev)

Расширенная статистика и метрики для Nginx.

Описание
--------

Nginx "из коробки" меет крайне скупую статистику, предоставляемую модулем [status](http://nginx.org/ru/docs/http/ngx_http_status_module.html).
Стоит отметить, что в Nginx Plus этот модуль даёт побольше информации.

К счастью, существует модуль [lua](https://github.com/openresty/lua-nginx-module) для Nginx, с помощью которого можно получить несколько больше того, что даёт status.

Metrix целиком и полностью написан на lua.

**Основные фичи Metrix:**
* открытый исходный код (лицензия MIT, см. [LICENCE](/LICENCE))
* модульность
* расширяемость (в будущем)
* полное покрытие тестами

[![Screenshot](/doc/screenshot_preview.png)](/doc/screenshot.png)

Системные требования
--------------------

* nginx >= 1.6.0, рекомендуется >= 1.9.0
* lua-nginx-module >= 0.9.17
* luarocks >= 2.0

Использование
-------------
Nginx и модуль lua-nginx-module устанавливаются согласно их инструкциям.

### Установка модуля metrix
Есть два варианта установки: глобально и локально.

**Установка глобально**
```
luarocks install nginx-metrix
```

**Установка локально**
```
luarocks install nginx-metrix --local
```

*Есть маленький трюк, позволяющий установить в произвольную папку - указать переменную окружения HOME при выполнении `luarocks install`*

### Конфигурирование Nginx

1\. В секцию `http` конфига необходимо добавить:

```
lua_shared_dict metrix 16m; # задаём хранилище метрик размером в 16МБ

#lua_package_path '/home/user/.luarocks/share/lua/5.1/?.lua;;'; # Нужно только если модуль ставился локально
#lua_package_cpath '/home/user/.luarocks/lib/lua/5.1/?.so;;';   # Нужно только если модуль ставился локально

# инициализация metrix
# в vhosts можно (но не обязательно) перечислить первичные server_name всех виртуалхостов
init_by_lua_block {
  metrix = require 'nginx-metrix.main'({
    shared_dict = 'metrix',
    vhosts = {'mydomain1', 'mydomain2', ...}
  })
}

# иницализация внутреннего воркера для пересчёта статистик
init_worker_by_lua_block {
  metrix.init_scheduler()
}
```

2\. В каждый виртуалхост (секции `server`) минимально необходимо добавить следующий блок для собственно сбора статистик

```
log_by_lua_block {
  metrix.handle_ngx_phase()
}
```

3\. Для вывода собранной статитики есть два пути:

&nbsp;&nbsp;&nbsp;&nbsp;1\. Специальный `location` в имеющихся виртуалхостах (`server`):
```
location /metrix/ {
  default_type 'text/plain';
  content_by_lua_block {
    metrix.show()
  }
}
```
&nbsp;&nbsp;&nbsp;&nbsp;2\. Отдельный виртуалхост (`server`):

```
server {
    listen 81;
    server_name metrix;

    location / {
        default_type 'text/plain';
        content_by_lua_block {
          metrix.show({vhosts_filter='.*'})
        }
    }
}
```

*Замечание 1: Вы самостоятельно должны позаботиться о безопасности. Например с помщью правил allow/deny или авторизации.*

*Замечание 2: Можно комбинировать оба этих метода.*

### Просмотр статистики

Минимально достаточно открыть в браузере адрес сконфигурированный для вывода статистики.

Для `location` внутри существующего виртуалхоста это будет что-то вроде http://mydomain/metrix/ .
Для отдельного виртуалхоста - http://metrix:81/ .

Статистику можно увидеть в 3х форматах: `text`, `html` и `json`.
Если формат не указан явно в url'e (например, http://metrix:81/?format=json), то metrix пытается определить его по HTTP-заголовку `Accept`.
Если и это не удалось, то статистика отображается в текстовом формате.

В случае если используется `location` внутри существующего виртуалхоста статистика отображается только по этому виртуалхосту.

В случае же отдельного виртуалхоста - по всем виртуалхостам подпадающим под `vhosts_filter`.
Также можно посмотреть список всех доступных виртуалхостов - http://metrix:81/?list_vhosts=1 (параметр `format` тоже применим).
Или статистику по одному виртуалхосту - http://metrix:81/?vhosts=mydomain (параметр `format` тоже применим).

#### Метрики включённые в поставку

1. **request**
    1. `rps` - общее количество запросов в секунду
    1. `internal_rps` - количество внутренних запросов в секунду
    1. `https_rps` - количество https-запросов в секунду
    1. `time_ps` - среднее время обработки запроса
    1. `length_ps` - средняя длина запроса
1. **status** - количество запросов группированное по статусу ответа (200, 301, 302, 404, 500 и т.д.).
1. **upstream**
    1. `rps` - количество запросов переданных на апстримы в секунду
    1. `connect_time` - среднее время соединения с апстримом
    1. `header_time` - среднее время обмена http-заголовками
    1. `response_time` - среднее время ответа апстрима

Расширение функционала
----------------------

Инстукция по созданию собственных метрик: [COOKBOOK-COLLECTORS.md](/doc/COOKBOOK-COLLECTORS.md).

Помощь проекту
--------------

См. [CONTRIBUTING.md](/CONTRIBUTING.md). Приветствуются любые вопросы, предложения и пул-реквесты.

Лицензия
--------

Авторские права 2016 ООО «Информационное агентство «Банки.ру». Лицензия MIT. За подробностями обращайтесь к [LICENSE](/LICENSE).
