For column:
  w_color TYPE lvc_s_colo.

  w_color-col = 1.
  w_color-int = 0.
  w_color-inv = 0.


  lr_column ?= lr_columns->get_column( columnname = v_fieldname ).
  lr_column->set_color( w_color ).



1 gray-blue headers

2 light gray list bodies

3 yellow totals

4 blue-green key columns

5 green positive threshold value

6 red negative threshold value
7 orange Control levels