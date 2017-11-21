# sporetest

## Installation
```
git clone https://github.com/incubaid/tarantool && cd tarantool/sporetest/todoapp
pip install -r requirements.txt
python3 manage.py createdb
python3 manage.py loadfixtures

luarocks install penlight
luarocks install lua-spore
```


## Running
### Running backend rest API
`cd todoapp && python3 manage.py runserver`

### Running Spore client
`lua main.lua`
