import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';

import '../home_screen/utils/SVCommon.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: svGetScaffoldColor(),
        iconTheme: IconThemeData(color: context.iconColor),
        title: Text('About Us', style: boldTextStyle(size: 20)),
        elevation: 0,
        centerTitle: true,
        actions: const [
          // IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
        ],
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: svGetBodyColor()),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  ''''Welcome to Doctak.net!
Our Mission
At Doctak.net, our mission is to create a comprehensive and innovative social network for doctors and medical students worldwide. We strive to connect medical professionals, provide valuable resources, and foster collaboration and knowledge-sharing across the healthcare community.
Who We Are
Doctak.net is a cutting-edge platform designed specifically for doctors. Our team consists of healthcare professionals, tech enthusiasts, and industry experts who are passionate about revolutionizing the way doctors interact and access information.
What We Offer
	•	Job Opportunities: Explore the latest job openings across the Middle East and India, with plans to expand globally.
	•	Country-Specific Drug Lists: Access comprehensive drug information tailored to each country.
	•	Professional Networking: Connect with peers, form groups, and discuss medical cases.
	•	AI-Powered Features: Utilize the latest in artificial intelligence to enhance your medical practice.
	•	Medical Conferences: Stay updated on conferences worldwide and never miss an important event.
	•	Medical Guidelines: Access the latest medical guidelines to stay informed on best practices and treatment protocols.
	•	Ministry of Health Updates and Notifications: Receive timely updates and notifications from ministries of health in your concerned country.
	•	Continuing Medical Education (CME): Earn CME credits and keep your knowledge up-to-date.
	•	Differential Diagnosis: Utilize advanced artificial intelligence to aid in accurate differential diagnosis, enhancing diagnostic precision and efficiency.
How AI Supports Differential Diagnosis
At Doctak.net, we leverage advanced artificial intelligence technologies to support doctors in making accurate and timely differential diagnoses. Our AI algorithms analyze the given patient data, symptoms, and medical histories to generate insights and suggest potential diagnoses. This assists healthcare professionals in making informed decisions and improving patient care outcomes.
Case Discussion
Engage in in-depth discussions on medical cases with your peers, leveraging AI insights to explore differential diagnoses and treatment strategies collaboratively.
Follow Us
Stay connected and follow us on social media:
	•	Facebook: [Insert Facebook page link] 
	•	LinkedIn: [Insert LinkedIn page link]
Contact Us
Have questions or feedback? Contact us:
	•	Email: [our email address]
	•	WhatsApp : [Link]
	•	Address: [Insert physical address, if applicable

Our Vision
We envision a world where doctors are seamlessly connected, empowered with the latest technology, and have access to a wealth of resources that support their professional growth and improve patient care.
Our Values
	•	Innovation: We embrace the latest technological advancements to provide cutting-edge solutions for the medical community.
	•	Collaboration: We believe in the power of collaboration and strive to create a platform where doctors can share knowledge and support each other.
	•	Excellence: We are committed to providing the highest quality resources and services to our users.
	•	Integrity: We maintain the highest standards of integrity and ethics in everything we do.


Join Us
Be a part of the Doctak.net community and experience a new era of medical networking and resources. Together, we can advance the field of medicine and improve healthcare outcomes worldwide.
Thank you for choosing Doctak.net!
              ''',
                  style: GoogleFonts.poppins(
                    fontSize: 16.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
