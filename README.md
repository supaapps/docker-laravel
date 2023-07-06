# Laravel docker

## Clone docker compose example to Laravel project

Go to Laravel project then run:

```sh
GITHUB_TOKEN=YOUR_TOKEN_HERE
curl -H "Authorization: token $GITHUB_TOKEN" \
  -L https://raw.githubusercontent.com/supaapps/docker-laravel/main/clone-example | bash $GITHUB_TOKEN
```
