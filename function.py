def str2num(str):
        try:
            if "." in str:
                return float(str)
            else:
                return int(str)
        except ValueError:
            return str

def group_dict(data, criteria:str, merged_key:str):
    merged_data = {}
    for item in data:
        entity = item[criteria]
        hwabang = item[merged_key]
        if entity in merged_data:
            merged_data[entity][merged_key].extend(hwabang)
        else:
            merged_data[entity] = {criteria: entity, merged_key: hwabang}
    return list(merged_data.values())

def transpose(l:list):
    return [list(d) for d in zip(*l)]

def del_column(l:list, columns:list[int]):
    columns.sort(reverse=True)
    for c in columns:
        for row in l:
            del row[c]

def add_column(l:list, value:list[any]):
    for row, v in zip(l, value):
        row.append(v)