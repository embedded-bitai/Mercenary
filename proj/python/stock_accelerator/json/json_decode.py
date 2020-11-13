import json

json_str = '{ \
	"name": "Samsung", \
	"id": 12345, \
	"history": [ \
		{"date": "2015-03-11", "vendor": "Intel"}, \
		{"date": "2016-03-07", "vendor": "ARM"} \
	] \
}'

dict = json.loads(json_str)

print(dict['name'])
for h in dict['history']:
	print(h['date'], h['vendor'])
