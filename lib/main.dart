import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Appointment',
      color: Colors.white,
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: MyHomePage(title: 'Appointment'),
    );
  }
}



class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}



class _MyHomePageState extends State<MyHomePage> {

  String username="9888888882";
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  var dateFormatter = DateFormat('dd MMM yyyy');
  DateTime today= DateTime.now();
  Map count={"9 AM - 10 AM":0,"10 AM - 11 AM":0,"11 AM - 12 PM":0,"5 PM - 6 PM":0,"6 PM - 7 PM":0,"7 PM - 8 PM":0};
  DatabaseReference databaseReference = FirebaseDatabase.instance.reference();
  String selectedDayString = "";
  CalendarController _calendarController;
  bool isWeekend=true, isPastday=false;

  void initState() {
    super.initState();
    fetchdata(dateFormatter.format(today));
    _calendarController = CalendarController();
    selectedDayString=dateFormatter.format(today);
    today.weekday==7 ? isWeekend=true : isWeekend=false;
  }

  void _onDaySelected(DateTime day, List events) {
    selectedDayString = dateFormatter.format(day); // get selected date string
    print(day.difference(today).inDays);
    if (day.difference(today).inDays<0){
      setState(() {
        isPastday=true;
      });
    }
    else if (day.weekday==7){
      setState(() {
        isPastday=false;
        isWeekend=true;
      });
    }
    else{
      fetchdata(selectedDayString);
      setState(() {
        isPastday=false;
        isWeekend=false;
      });
    }
  }

  void fetchdata(String selectedDay) {
    databaseReference.child("appointments").child(selectedDay).once().then((DataSnapshot datasnapshot) {
      try {
        count={"9 AM - 10 AM":0,"10 AM - 11 AM":0,"11 AM - 12 AM":0,"5 PM - 6 PM":0,"6 PM - 7 PM":0,"7 PM - 8 PM":0};
        Map<String, dynamic> mapOfMaps = Map.from( datasnapshot.value );
        mapOfMaps.forEach((k,v) => count[k]=v.length-1);
        setState(() {
        });
      }
      on NoSuchMethodError{
        setState(() {
          count={"9 AM - 10 AM":0,"10 AM - 11 AM":0,"11 AM - 12 AM":0,"5 PM - 6 PM":0,"6 PM - 7 PM":0,"7 PM - 8 PM":0};
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(widget.title,style: TextStyle(color: Colors.white),),
          backgroundColor: Colors.orange,
        ),
        body:Column(
          children: <Widget>[
            TableCalendar(
              initialCalendarFormat: CalendarFormat.week,
              calendarController: _calendarController,
              startingDayOfWeek: StartingDayOfWeek.monday,
              daysOfWeekStyle: DaysOfWeekStyle(weekendStyle: TextStyle(color: Colors.orange)),
              calendarStyle: CalendarStyle(
                selectedColor: Colors.orange,
                todayColor: Colors.orange[200],
                outsideDaysVisible: false,
                weekendStyle: TextStyle(color: Colors.orange),
              ),
              onDaySelected: _onDaySelected,
            ),
            Center(child: Text("Showing available slots for ${selectedDayString}",style: TextStyle(color: Colors.deepOrangeAccent),)),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    isPastday ?
                      Container(child:Text("No Appointments!")):
                      display_schedule(isWeekend),
                  ],
                ),
              ),
            ),
          ],
        )
    );
  }

  Widget display_schedule(bool isWeekend){
    return !isWeekend ? Column(
        children: <Widget>[
        for (var i in count.keys)
          Container(
            width: double.infinity,height: 80,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(width:100,child: Text(i,style: TextStyle(decoration: count[i]>=5 ? TextDecoration.lineThrough:null,fontSize: 16),)),
                        count[i]<4 ?
                        Text("${count[i]} slots filled",style: TextStyle(color: Colors.grey,fontStyle: FontStyle.italic),):
                        count[i]==4 ?
                          Text("1 slot left",style: TextStyle(color: Colors.grey,fontStyle: FontStyle.italic),):
                          Container()
                      ],
                    ),
                    count[i] < 5 ?
                    RaisedButton(
                      child:Text("Book",style:TextStyle(color:Colors.white)),
                      color: Colors.orange,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                      ),
                      onPressed: (){
                      showAlertDialog(context, "Book Appointment for ${selectedDayString} at ${i}?",i);
                      },
                    ) :
                    Text("Sorry, no slot left!",style: TextStyle(color: Colors.grey,fontStyle: FontStyle.italic),),
                  ],
                ),
                SizedBox(width:10,height: 0.7,child: Container(color: Colors.grey,),)
              ],
            )
          )
        ],
    ) :
    SizedBox(height:300,child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Image.asset("assets/Relaxation.gif",width: 200,height: 200,),
        Center(child: Text("Sunday Closed!",style: TextStyle(fontSize: 20,color: Colors.grey),)),
      ],
    ));
  }



  /////////////////////////////// Alert Dialog ///////////////////////////////////////

  showAlertDialog(BuildContext context, String message,String time) {
    Widget yesbutton = FlatButton(
      color: Colors.orange,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
          side: BorderSide(color: Colors.orange)),
      child: Text("Yes", style: TextStyle(color: Colors.white)),
      onPressed: () {
        databaseReference.child("appointments").child(selectedDayString).child(time).update({((count[time]+1).toString()):username});
        fetchdata(selectedDayString);

        Navigator.of(context, rootNavigator: true).pop();
        _scaffoldKey.currentState.showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text('Your Appointment is on ${selectedDayString} at ${time}'),
              duration: Duration(seconds: 5),
            ));
      },
    );

    Widget cancelbutton = FlatButton(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
          side: BorderSide(color: Colors.orange)),
      child: Text("Cancel", style: TextStyle(color: Colors.orange)),
      onPressed: () {
        Navigator.of(context, rootNavigator: true).pop();
      },
    );

    AlertDialog alert = AlertDialog(
      titlePadding: EdgeInsets.all(0),
      title: Container(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("Confirmation", style: TextStyle(color: Colors.white)),
        ),
        color: Colors.orange,
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
      ),
      actions: [cancelbutton,yesbutton],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );

  }

   /////////////////////////////// Alert Dialog End ///////////////////////////////////////
}
