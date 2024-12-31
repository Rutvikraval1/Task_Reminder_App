import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:task_reminder_app/controllers/device_info.dart';
import 'package:task_reminder_app/controllers/task.controller.dart';
import 'package:task_reminder_app/models/task.dart';
import 'package:task_reminder_app/services/notification_services.dart';
import 'package:task_reminder_app/services/theme_services.dart';
import 'package:task_reminder_app/theme/theme.dart';
import 'package:task_reminder_app/ui/add_task_bar.dart';
import 'package:task_reminder_app/ui/widgets/task_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Task> filterTaskList = [];
  List<Task> filterTaskListTemp = [];

  double? width;
  double? height;

  NotifyHelper? notifyHelper;
  String? deviceName;
  bool shorted = false;

  DateTime _selectedDate = DateTime.now();
  final _taskController = Get.put(TaskController());

  @override
  void initState() {
    super.initState();

    getData();

    DeviceInfo deviceInfo = DeviceInfo();
    deviceInfo.getDeviceName().then((value) {
      setState(() {
        deviceName = value;
      });
    });

    notifyHelper = NotifyHelper();
    notifyHelper?.initializeNotification();
    notifyHelper?.requestIOSPermissions();
    notifyHelper?.requestAndroidPermissions();
  }
  Future<void> getData() async {
    await _taskController.getTasks();
    filterTaskList=[];
    filterTaskListTemp = _taskController.taskList;
    print("getData _selectedDate = $_selectedDate ");
    for(int i=0;i<filterTaskListTemp.length;i++){
      // Parse the dates to DateTime for accurate comparison
      DateTime taskDate = DateFormat('M/d/yyyy').parse(filterTaskListTemp[i].date.toString());
      DateTime selectedDate = DateFormat('MM/dd/yyyy').parse(DateFormat('MM/dd/yyyy').format(_selectedDate));
      print("taskDate = $taskDate");
      print("selectedDate = $selectedDate");

      if (taskDate == selectedDate) {
        filterTaskList.add(filterTaskListTemp[i]);
      }
    }
    print(filterTaskList.length);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    return GetBuilder<ThemeServices>(
      init: ThemeServices(),
      builder: (themeServices) => Scaffold(
        backgroundColor: context.theme.colorScheme.surface,
        appBar: _appBar(themeServices),
        body: Column(
          children: [
            _addTaskBar(),
            _dateBar(),
            const SizedBox(height: 10),
            _showTasks(),
          ],
        ),
        floatingActionButton: SizedBox(
          height: 60,
          width: 60,
          child: FloatingActionButton(
            onPressed: ()async{
              await Get.to(() => const AddTaskPage())?.then((value) async {
                await _taskController.getTasks();
                getData();
              },);

            },
            child:const Icon(Icons.add,color: Colors.white,size: 28,)
          ),
        ),
      ),
    );
  }

  _addTaskBar() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat("EEE, d MMM yyyy").format(DateTime.now()),
            style: headingStyle.copyWith(fontSize: width! * .05),
          ),
          Text(
            "Today",
            style: headingStyle.copyWith(fontSize: width! * .05),
          ),

        ],
      ),
    );
  }

  AppBar _appBar(ThemeServices themeServices) {
    return AppBar(
      systemOverlayStyle: Get.isDarkMode
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      backgroundColor: context.theme.colorScheme.surface,
      elevation: 0,
      leading: GestureDetector(
        onTap: () {
          themeServices.switchTheme();
        },
        child: themeServices.icon,
      ),
      actions: [
        InputChip(
          padding: const EdgeInsets.all(0),
          label: Text(
            deviceName ?? "Unknown",
            style: GoogleFonts.lato(
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 10,)
      ],
    );
  }

  _dateBar() {
    return Container(
      margin: const EdgeInsets.only(top: 20, left: 10),
      child: DatePicker(
        DateTime.now(),
        height: 125,
        width: 80,
        initialSelectedDate: DateTime.now(),
        selectionColor: primaryColor,
        selectedTextColor: Colors.white,
        onDateChange: (date) {
          // New date selected
          setState(() {
            _selectedDate = date;
          });
          getData();
        },
        monthTextStyle: GoogleFonts.lato(
          textStyle: TextStyle(
            fontSize: width! * 0.039,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        dateTextStyle: GoogleFonts.lato(
          textStyle: TextStyle(
            fontSize: width! * 0.037,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        dayTextStyle: GoogleFonts.lato(
          textStyle: TextStyle(
            fontSize: width! * 0.030,
            fontWeight: FontWeight.normal,
            color: Get.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  _showTasks() {
    return Expanded(
      child: ListView.builder(
        itemCount: filterTaskList.length,
        itemBuilder: (_, index) {
          Task task = filterTaskList[filterTaskList.length - 1 - index];
          DateTime date = _parseDateTime(task.startTime.toString());
          var myTime = DateFormat.Hm().format(date);
          int mainTaskNotificationId = task.id!.toInt();
          int reminderNotificationId = mainTaskNotificationId + 1;
          DateTime taskDate = DateFormat('M/d/yyyy').parse(task.date.toString());
          DateTime selectedDate = DateFormat('MM/dd/yyyy').parse(DateFormat('MM/dd/yyyy').format(_selectedDate));
          print("taskDate = $taskDate");
          print("selectedDate = $selectedDate");
          if (taskDate == selectedDate) {
            notifyHelper?.scheduledNotification(
              int.parse(myTime.toString().split(":")[0]), //hour
              int.parse(myTime.toString().split(":")[1]), //minute
              task,
            );
            notifyHelper?.cancelNotification(reminderNotificationId);
          }
            return AnimationConfiguration.staggeredList(
              position: index,
              child: SlideAnimation(
                child: FadeInAnimation(
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _showBottomSheet(context, task);
                        },
                        child: TaskTile(
                          task,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );

        },
      ),
    );
  }

  DateTime _parseDateTime(String timeString) {
    List<String> components = timeString.split(' ');

    List<String> timeComponents = components[0].split(':');
    int hour = int.parse(timeComponents[0]);
    int minute = int.parse(timeComponents[1]);
    if (components.length > 1) {
      String period = components[1];
      if (period.toLowerCase() == 'pm' && hour < 12) {
        hour += 12;
      } else if (period.toLowerCase() == 'am' && hour == 12) {
        hour = 0;
      }
    }

    return DateTime(DateTime.now().year, DateTime.now().month,
        DateTime.now().day, hour, minute);
  }

  void _showBottomSheet(BuildContext context, Task task) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.only(top: 4),
        height: task.isCompleted == 1
            ? MediaQuery.of(context).size.height * 0.32
            : MediaQuery.of(context).size.height * 0.42,
        color: Get.isDarkMode ? darkGreyColor : Colors.white,
        width: double.infinity,
        child: Column(children: [
          const SizedBox(height: 8,),
          Container(
            height: 6,
            width: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Get.isDarkMode ? Colors.grey[600] : Colors.grey[300],
            ),
          ),
          const Spacer(),
          _bottomSheetButton(
            label: " Update Task",
            color: Colors.green[400]!,
            onTap: () {
              Get.back();
              Get.to(() => AddTaskPage(task: task));
            },
            context: context,
            icon: Icons.update,
          ),
          task.isCompleted == 1
              ? Container()
              : _bottomSheetButton(
                  label: "Task Completed",
                  color: primaryColor,
                  onTap: () {
                    Get.back();
                    _taskController.markTaskAsCompleted(task.id!, true);
                    _taskController.getTasks();
                    getData();
                  },
                  context: context,
                  icon: Icons.check,
                ),
          _bottomSheetButton(
            label: "Delete Task",
            color: Colors.red[400]!,
            onTap: () {
              Get.back();
              showDialog(
                  context: context,
                  builder: (_) => _alertDialogBox(context, task));
            },
            context: context,
            icon: Icons.delete,
          ),
          const SizedBox(height: 15),
          _bottomSheetButton(
            label: "Close",
            color: Colors.red[400]!.withOpacity(0.5),
            isClose: true,
            onTap: () {
              Get.back();
            },
            context: context,
            icon: Icons.close,
          ),
        ]),
      ),
    );
  }

  _alertDialogBox(BuildContext context, Task task) {
    return AlertDialog(
      backgroundColor: context.theme.colorScheme.surface,
      icon: const Icon(Icons.warning, color: Colors.red),
      title: const Text("Are you sure you want to delete?"),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            onPressed: () {
              Get.back();
              _taskController.deleteTask(task.id!);
              getData();
            },
            child: const SizedBox(
              width: 60,
              child: Text(
                "Yes",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Get.back();
            },
            child: const SizedBox(
              width: 60,
              child: Text(
                "No",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _bottomSheetButton(
      {required String label,
      required BuildContext context,
      required Color color,
      required Function()? onTap,
      IconData? icon,
      bool isClose = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(vertical: 7),
        height: 55,
        width: MediaQuery.of(context).size.width * 0.9,

        decoration: BoxDecoration(
          border: Border.all(
            width: 2,
            color: isClose
                ? Get.isDarkMode
                    ? Colors.grey[700]!
                    : Colors.grey[300]!
                : color,
          ),
          borderRadius: BorderRadius.circular(20),
          color: isClose ? Colors.transparent : color,
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon != null
                ? Icon(
                    icon,
                    color: isClose
                        ? Get.isDarkMode
                            ? Colors.white
                            : Colors.black
                        : Colors.white,
                    size: 30,
                  )
                : const SizedBox(),
            Text(
              label,
              style: titleStyle.copyWith(
                fontSize: 18,
                color: isClose
                    ? Get.isDarkMode
                        ? Colors.white
                        : Colors.black
                    : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Task> getTasksCompletedToday(List<Task> taskList) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    return taskList.where((task) {
      if (task.completedAt == null) {
        return false;
      }

      DateTime completedDate = DateTime.parse(task.completedAt!);
      completedDate = DateTime(
        completedDate.year,
        completedDate.month,
        completedDate.day,
      );

      return completedDate == today;
    }).toList();
  }
}
