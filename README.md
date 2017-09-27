#Тестовое задание - сокращатель ссылок.

Сделать API на sinatra или rails с использованием веб сервера thin. Апи создает короткие ссылки. Для бекенда использовать em-hiredis (или mysql2).
Пример, Запрос создания ссылок:

```
POST /
Content-Type: application/json
{
"longUrl": "https://www.rust-lang.org/ru-RU/documentation.html"
}

Ответ: 
200 OK
Content-Type: application/json
{
"url": "http://127.0.0.1/fj5uhd74"
}

Запрос перехода:
GET /fj5uhd74

Ответ:
HTTP/1.1 301 Moved Permanently
Location: https://www.rust-lang.org/ru-RU/documentation.html
```
