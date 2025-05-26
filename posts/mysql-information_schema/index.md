# MySQL 数据库信息统计


## information_schema 库

### 统计单表占用物理空间大小

查询表: information_schema.tables

计算公式: 

- 方法一: 单表占用空间大小 = AVG_ROW_LENGTH * TABLE_ROWS + INDEX_LENGTH
- 方法二: 单表占用空间大小 = DATA_LENGTH

*示例: 查看 employees 库中 salaries 表的占用空间大小*

```bash
mysql> select table_schema,table_name, 
    -> (avg_row_length * table_rows + index_length) / 1024 / 1024 as data_mb
    -> from tables where table_schema='employees' and table_name = 'salaries';
+--------------+------------+-------------+
| table_schema | table_name | data_mb     |
+--------------+------------+-------------+
| employees    | salaries   | 94.74268913 |
+--------------+------------+-------------+
```

### 查看数据库碎片占用最大的表, 前 10 名

```bash
mysql> select table_schema,table_name, data_free / 1024 / 1024 as data_free_mb from tables order by data_free_mb limit 10;
```
