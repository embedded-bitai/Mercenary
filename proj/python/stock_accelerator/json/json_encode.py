import json

customer = {
	'id': 12345,
	'name': 'samsung',
	'history': [
		{'date': '2015-03-11', 'vendor': 'Intel'},
		{'date': '2016-03-07', 'vendor': 'ARM'},
	]
}

json_str = json.dumps(customer)

print(json_str)
print(type(json_str))

json_str = json.dumps(customer, indent=4)

print(json_str)
print(type(json_str))
