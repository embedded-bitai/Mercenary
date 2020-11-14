import csv
import json

input_file_name = "./삼성전자.csv"
output_file_name = "convert.json"

with open(input_file_name, "r", encoding="utf-8", newline="") as input_file, \
	open(output_file_name, "w", encoding="utf-8", newline="") as output_file:

	reader = csv.reader(input_file)

	print(reader)

	col_names = next(reader)

	for cols in reader:
		doc = {col_name: col for col_name, col in zip(col_names, cols)}
		print(doc)
		print(json.dumps(doc, ensure_ascii=False), file=output_file)
