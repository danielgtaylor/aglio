FORMAT: 1A
HOST: https://api.mywebsite.com

# API Title
[Markdown](http://daringfireball.net/projects/markdown/syntax) **formatted** description.

## Subtitle
Also Markdown *formatted*. This also includes automatic "smartypants" formatting -- hooray!

> "A quote from another time and place"

Another paragraph. Code sample:

```http
Authorization: bearer 5262d64b892e8d4341000001
```

And some code with no highlighting:

```no-highlight
Foo bar baz
```

# Group Notes
Group description (also with *Markdown*)

## Note List [/notes]
Note list description

+ Even
+ More
+ Markdown

+ Model

    + Headers

            Content-Type: application/json
            X-Request-ID: f72fc914
            X-Response-Time: 4ms

    + Body

            [
                {
                    "id": 1,
                    "title": "Grocery list",
                    "body": "Buy milk"
                },
                {
                    "id": 2,
                    "title": "TODO",
                    "body": "Fix garage door"
                }
            ]

### Get Notes [GET]
Get a list of notes.

+ Response 200
    
    [Note List][]

### Create New Note [POST]
Create a new note

+ Request

    + Headers

            Content-Type: application/json

    + Body

            {
                "title": "My new note",
                "body": "..."
            }

+ Response 201

+ Response 400

    + Headers

            Content-Type: application/json

    + Body

            {
                "error": "Invalid title"
            }

## Note [/notes/{id}]
Note description

+ Parameters

    + id (required, string, `68a5sdf67`) ... The note ID

+ Model

    + Headers

            Content-Type: application/json
            X-Request-ID: f72fc914
            X-Response-Time: 4ms

    + Body

            {
                "id": 1,
                "title": "Grocery list",
                "body": "Buy milk"
            }

### Get Note [GET]
Get a single note.

+ Response 200

    [Note][]

+ Response 404

    + Headers

            Content-Type: application/json
            X-Request-ID: f72fc914
            X-Response-Time: 4ms

    + Body

            {
                "error": "Note not found"
            }

### Update a Note [PUT]
Update a single note

+ Request

    + Headers

            Content-Type: application/json

    + Body

            {
                "title": "Grocery List (Safeway)"
            }

+ Response 200

    [Note][]

+ Response 404

    + Headers

            Content-Type: application/json
            X-Request-ID: f72fc914
            X-Response-Time: 4ms

    + Body

            {
                "error": "Note not found"
            }

### Delete a Note [DELETE]
Delete a single note

+ Response 204

+ Response 404

    + Headers

            Content-Type: application/json
            X-Request-ID: f72fc914
            X-Response-Time: 4ms

    + Body

            {
                "error": "Note not found"
            }

# Group Users
Group description

## User List [/users{?name,joinedBefore,joinedAfter,sort,limit}]
A list of users

+ Parameters

    + name (optional, string, `alice`) ... Search for a user by name
    + joinedBefore (optional, string, `2011-01-01`) ... Search by join date
    + joinedAfter (optional, string, `2011-01-01`) ... Search by join date
    + sort = `name` (optional, string, `joined`) ... Which field to sort by

        + Values
            + `name`
            + `joined`
            + `-joined`

    + limit = `10` (optional, integer, `25`) ... The maximum number of users to return, up to `50`

+ Model

    + Headers

            Content-Type: application/json

    + Body

            [
                {
                    "name": "alice",
                    "image": "http://foo.com/alice.jpg",
                    "joined": "2013-11-01"
                },
                {
                    "name": "bob",
                    "image": "http://foo.com/bob.jpg",
                    "joined": "2013-11-02"
                }
            ]

    + Schema

            {
                "type": "array",
                "maxItems": 50,
                "items": {
                    "type": "object",
                    "properties": {
                        "name": {
                            "type": "string"
                        },
                        "image": {
                            "type": "string"
                        },
                        "joined": {
                            "type": "string",
                            "pattern": "\d{4}-\d{2}-\d{2}"
                        }
                    }
                }
            }

### Get users [GET]
Get a list of users. Example:

```no-highlight
https://api.mywebsite.com/users?sort=joined&limit=5
```

+ Response 200

    [User List][]

# Group Tags
Get or set tags on notes

## GET /tags
Get a list of bars

+ Response 200

## Get one tag [/tags/{id}]
Get a single tag

### GET

+ Response 200
