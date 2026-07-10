extends Control

@onready var rec_container = $TopLeftContainer / VBoxContainer / HBoxContainer_REC
@onready var date_time_label = $TopLeftContainer / VBoxContainer / DateTimeLabel

func _process(_delta):
	update_date_time()
	blink_rec()

func update_date_time():
	var time_dict = Time.get_datetime_dict_from_system()


	var months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
	var month_str = months[time_dict.month - 1]
	var day_str = "%02d" % time_dict.day
	var year_str = str(time_dict.year)


	var hour = time_dict.hour
	var am_pm = "AM"
	if hour >= 12:
		am_pm = "PM"
		if hour > 12: hour -= 12
	if hour == 0: hour = 12

	var hour_str = "%02d" % hour
	var minute_str = "%02d" % time_dict.minute
	var second_str = "%02d" % time_dict.second

	var final_str = "%s %s %s - %s:%s:%s %s" % [month_str, day_str, year_str, hour_str, minute_str, second_str, am_pm]

	if date_time_label:

		date_time_label.text = final_str.to_upper()

func blink_rec():
	if rec_container:

		var msec = Time.get_ticks_msec() % 1000

		rec_container.visible = (msec < 500)
