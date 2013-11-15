FORMAT: 1A
HOST: https://api.mywebsite.com

# API Title
Markdown **formatted** description.

## Subtitle
Also Markdown *formatted*.

Another paragraph. Code sample:

```http
Authorization: bearer 5262d64b892e8d4341000001
```

And some code with no highlighting:

```no-highlight
Foo bar baz
```

# Group Notes
Group description

## Note List [/notes]
Note list description

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

            Content-Type: applicatoin/json

    + Body

        {
            "title": "My new note",
            "body": "..."
        }

+ Response 201

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

### Delete a Note [DELETE]
Delete a single note

+ Response 204

# Group Users
Group description

## User List [/users{?name,joinedBefore,joinedAfter,limit}]
A list of users

+ Parameters

    + name (optional, string, `alice`) ... Search for a user by name
    + joinedBefore (optional, string, `2011-01-01`) ... Search by join date
    + joinedAfter (optional, string, `2011-01-01`) ... Search by join date
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

### Get users [GET]
Get a list of users

+ Response

    [User List][]
