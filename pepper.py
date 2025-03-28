import os
import sys
script_dir = os.path.dirname(os.path.realpath(__file__))
sys.path.append(script_dir)
from typing import Literal
import json
import win32com.client
import function
from datetime import datetime


def transpose(l:list):
    return [list(d) for d in zip(*l)]
    
if __name__ =="__main__":

    print("hello")
    input_data=sys.argv[1]
    file_path=sys.argv[2]
    farm_name=sys.argv[3]
    last_date=sys.argv[4]
    date=sys.argv[5]
    data=json.loads(input_data)
    keys = data[0].keys()
    data = [list(item.values()) for item in data] 
    excel = win32com.client.Dispatch("Excel.Application")
    excel.Visible=True
    num_entity=len(data)
    workbook = excel.Workbooks.Open(file_path)
    ws=workbook.Sheets("생육조사")
    used_range = ws.UsedRange  # 사용된 범위 가져오기
    rows = used_range.Rows.Count
    data = transpose(data)
    data.insert(0, ["=농가정보!$C$7"]*num_entity)
    data.insert(1, [date]*num_entity)
    # data.insert(4, [1]*self.num_entity)
    last_data=None
    write_row=excel.Application.WorksheetFunction.CountA(ws.Range(ws.Cells(1, 2), ws.Cells(rows, 2)))+1
    last_data=ws.Range(ws.Cells(2, 2), ws.Cells(rows+1, 2)).Value
    last_date = datetime.strptime(last_date, "%Y-%m-%d").date()
    for row, v in enumerate(last_data, start=2):
        if not v[0] or isinstance(v[0], str):
            continue
        date=v[0].date()
        try:
            if last_date == date:
                write_row=row+num_entity
                lastdata=ws.Range(ws.Cells(row, 1), ws.Cells(row+num_entity-1, 1)).Value
                last_data= [list(rows) for rows in lastdata]
                last_data=[[0 if x is None else x for x in row] for row in last_data]
                break
        except TypeError:
            print(f"오류: 날짜 형식이 올바르지 않습니다.")
    if last_data:
        length_data=[f"=E{str(int(write_row)+r-num_entity)}+[@생장길이]" for r in range(num_entity)]
        data.insert(5, length_data)
    else:
        length_data=[""]*num_entity
        data.insert(5, length_data)
    data.insert(11, ["본주"]*num_entity)
    data = transpose(data)
    ws.Range(ws.Cells(write_row, 1), ws.Cells(write_row+len(data)-1, 1+len(data[0])-1)).Value=data
    workbook.Save()

