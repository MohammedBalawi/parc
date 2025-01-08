import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class MyCVScreen extends StatefulWidget {
  const MyCVScreen({super.key});

  @override
  State<MyCVScreen> createState() => _MyCVScreenState();
}

class _MyCVScreenState extends State<MyCVScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(''),
            const Text('My CV'),
            IconButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                icon: const Icon(Icons.arrow_forward_ios_outlined)),
          ],
        ),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mohammed Ahmad Al Balawi',
                          style: TextStyle(color: Colors.cyan, fontSize: 20),
                        ),
                        Text(
                          'Software Engineer',
                          style: TextStyle(color: Colors.black45, fontSize: 15),
                        ),
                        Text(
                          'Flutter Developer',
                          style: TextStyle(color: Colors.black45, fontSize: 15),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          '   - moudybalawi@gmail.com',
                          style: TextStyle(color: Colors.blue, fontSize: 13),
                        ),
                        Text(
                          '   - Gaza, Palestine',
                          style: TextStyle(color: Colors.black, fontSize: 13),
                        ),
                        Text(
                          '   - +972567663533',
                          style: TextStyle(color: Colors.black, fontSize: 13),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Container(
                            height: 150,
                            width: 150,
                            decoration: BoxDecoration(
                                color: Colors.cyan,
                                borderRadius: BorderRadius.circular(20)),
                            child: Image.asset(
                                'assets/image/image_profile.jpeg',
                                fit: BoxFit.cover),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'PROFESSIONAL SUMMARY',
                  style: TextStyle(color: Colors.blueAccent),
                ),
                const SizedBox(
                  height: 5,
                ),
                const Text(
                  'software engineering is not just a profession for me—it\'s a way of life. I am driven by the thrill of turning ideas into reality through elegant code and innovative solutions. I am excited about the opportunity to leverage my skills, enthusiasm, and determination to create software that will shape the future in meaningful way, Personally, I started studying flutter from 2021, at Vision plus company, it started with ul and then shared pref. after that database, more gtex and provider, finally api Within months, I was able to master the language, memorize titles, and create applications I started by making a ul part, then linking it to getx and databases. then linking it to an api. I have the determination to learn programming languages and develop myself. Now I am working on developing ExcelI have my own ideas and applications that help organizationsIt saves time and effort, is interactive, easy and usable for all groups ',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'SKILLS',
                  style: TextStyle(color: Colors.blueAccent),
                ),
                const SizedBox(
                  height: 5,
                ),
                const Text(
                  'FrontEnd :- HTML, CSS .',
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                const Text(
                  'Flutter :- ui , shared pref. , gtex , provider ,databases ,api ,firebase.',
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                const Text(
                  'Others :- data structures, algorithms, Java, Object-oriented programming, Problem-solving, Documenting SRS, Python, and infranss data at system .',
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'Personal Skills',
                  style: TextStyle(color: Colors.blueAccent),
                ),
                const SizedBox(
                  height: 5,
                ),
                const Text(
                  '- Able to build a projects',
                  style: TextStyle(color: Colors.black, fontSize: 13),
                ),
                const Text(
                  '- Able to analyze and modify the application.',
                  style: TextStyle(color: Colors.black, fontSize: 13),
                ),
                const Text(
                  '- Excellent abilities to communicate with others',
                  style: TextStyle(color: Colors.black, fontSize: 13),
                ),
                const Text(
                  '- I can perform my duties to the fullest.',
                  style: TextStyle(color: Colors.black, fontSize: 13),
                ),
                const Text(
                  '- I can work with team and deal with him.',
                  style: TextStyle(color: Colors.black, fontSize: 13),
                ),
                const Text(
                  '- I hava the ability to learn more and more languages in short time.',
                  style: TextStyle(color: Colors.black, fontSize: 13),
                ),
                const Text(
                  '- I can developing Excel',
                  style: TextStyle(color: Colors.black, fontSize: 13),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'PROGECT',
                  style: TextStyle(color: Colors.blueAccent),
                ),
                const SizedBox(
                  height: 5,
                ),
                const Text(
                  '• Flutter : I worked on flutter a large application ,in mobile application development, data entry development, and Excel development, and I have extensive experience in dealing with data. start design ui , then make action , after that bluid api , database , shared pref. ,gets ,provider and firebase .',
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                const Text(
                  '• Java : I worked on a Java programming project for a bank and hospital , The role that I played was to do the father\'s classes where my colleague did the sons classes .',
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'Training Courses',
                  style: TextStyle(color: Colors.blueAccent),
                ),
                const SizedBox(
                  height: 5,
                ),
                const Text(
                  '• Vision plus company : I learned flutter (120 HOURS) .',
                  style: TextStyle(color: Colors.black, fontSize: 13),
                ),
                const Text(
                  '• Hexa company : I work 2 months flutter developer ,infranss data at system before 7Qctober .',
                  style: TextStyle(color: Colors.black, fontSize: 13),
                ),
                const Text(
                  '• Center refeoues camp school Ahmed Neamr: I work months on wor , at batabesa and system .',
                  style: TextStyle(color: Colors.black, fontSize: 13),
                ),
                const Text(
                  '• Agricultural Relief: I work for Agricultural Relief in developing the Excel program .',
                  style: TextStyle(color: Colors.black, fontSize: 13),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'LANGUAGES',
                  style: TextStyle(color: Colors.blueAccent),
                ),
                const SizedBox(
                  height: 5,
                ),
                const Text(
                  '• English – Intermediate .',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const Text(
                  '• Arabic – Fluent .',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'EXPERIENCE',
                  style: TextStyle(color: Colors.blueAccent),
                ),
                const SizedBox(
                  height: 5,
                ),
                const Text(
                  'FLUTTER DEVELOPER .',
                  style: TextStyle(color: Colors.black, fontSize: 13),
                ),
                const Text(
                  'Freelancer on a standalone platfrm . IOct 2021 -Present .',
                  style: TextStyle(color: Colors.black, fontSize: 13),
                ),
                const Text(
                  'I has many achievements including .',
                  style: TextStyle(color: Colors.black, fontSize: 11),
                ),
                const Text(
                  '1- https://github.com/MohammedBalawi/answer_Iogin.git .',
                  style: TextStyle(color: Colors.black, fontSize: 10),
                ),
                const Text(
                  '2- https://github.com/MohammedBalawi/weather.git .',
                  style: TextStyle(color: Colors.black, fontSize: 10),
                ),
                const Text(
                  '3- https://github.cam/MohammedBalawi/api_user. git .',
                  style: TextStyle(color: Colors.black, fontSize: 10),
                ),
                const Text(
                  'Git Hub :MohemmedBalawi .',
                  style: TextStyle(color: Colors.black, fontSize: 13),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
