import 'package:doctak_app/core/utils/post_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

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
      backgroundColor: svGetBgColor(),
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HtmlWidget('''
  <h1>Welcome to DocTak.net</h1>

  <h2>Our Mission</h2>
  <p>At DocTak.net, our mission is to create a comprehensive and innovative social network for doctors and medical students worldwide. We strive to connect medical professionals, provide valuable resources, and foster collaboration and knowledge-sharing across the healthcare community.</p>

  <h2>Who We Are</h2>
  <p>DocTak.net is a cutting-edge platform designed specifically for doctors. Our team consists of healthcare professionals, tech enthusiasts, and industry experts who are passionate about revolutionizing the way doctors interact and access information.</p>

  <h2>What We Offer</h2>
  <ul>
    <li>Job Opportunities: Explore the latest job openings across the Middle East and India, with plans to expand globally.</li>
    <li>Country-Specific Drug Lists: Access comprehensive drug information tailored to each country.</li>
    <li>Professional Networking: Connect with peers, form groups, and discuss medical cases.</li>
    <li>AI-Powered Features: Utilize the latest in artificial intelligence to enhance your medical practice.</li>
    <li>Medical Conferences: Stay updated on conferences worldwide and never miss an important event.</li>
    <li>Medical Guidelines: Access the latest medical guidelines to stay informed on best practices and treatment protocols.</li>
    <li>Ministry of Health Updates and Notifications: Receive timely updates and notifications from ministries of health in your concerned country.</li>
    <li>Continuing Medical Education (CME): Earn CME credits and keep your knowledge up-to-date.</li>
    <li>Differential Diagnosis: Utilize advanced artificial intelligence to aid in accurate differential diagnosis, enhancing diagnostic precision and efficiency.</li>
  </ul>

  <h2>How AI Supports Differential Diagnosis</h2>
  <p>At DocTak.net, we leverage advanced artificial intelligence technologies to support doctors in making accurate and timely differential diagnoses. Our AI algorithms analyze the given patient data, symptoms, and medical histories to generate insights and suggest potential diagnoses. This assists healthcare professionals in making informed decisions and improving patient care outcomes.</p>

  <h2>Case Discussion</h2>
  <p>Engage in in-depth discussions on medical cases with your peers, leveraging AI insights to explore differential diagnoses and treatment strategies collaboratively.</p>
  <h2>Our Vision</h2>
  <p>We envision a world where doctors are seamlessly connected, empowered with the latest technology, and have access to a wealth of resources that support their professional growth and improve patient care.</p>
  <h2>Our Values</h2>
  <ul>
    <li>Innovation: We embrace the latest technological advancements to provide cutting-edge solutions for the medical community.</li>
    <li>Collaboration: We believe in the power of collaboration and strive to create a platform where doctors can share knowledge and support each other.</li>
    <li>Excellence: We are committed to providing the highest quality resources and services to our users.</li>
    <li>Integrity: We maintain the highest standards of integrity and ethics in everything we do.</li>
  </ul>

  <h2>Join Us</h2>
  <p>Be a part of the DocTak.net community and experience a new era of medical networking and resources. Together, we can advance the field of medicine and improve healthcare outcomes worldwide.</p>

  <p>Thank you for choosing DocTak.net!</p>
  '''),
                    const SizedBox(
                      height: 10,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Contact/Follow us here',style: GoogleFonts.poppins(color: Colors.black,fontSize: 20,fontWeight: FontWeight.w500),),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        GestureDetector(
                            onTap: () {
                              PostUtils.launchURL(context,
                                  'https://www.facebook.com/profile.php?id=100090277690568&mibextid=ZbWKwL');
                            },
                            child: Image.asset('assets/icon/face_icon.png')),
                        GestureDetector(
                            onTap: () {
                              PostUtils.launchURL(context,
                                  'https://www.linkedin.com/company/doctak-net/');
                            },
                            child:
                                Image.asset('assets/icon/linkedin_icon.png')),
                        GestureDetector(
                            onTap: () {
                              PostUtils.launchURL(
                                  context, 'https://wa.me/971504957572');
                            },
                            child: Image.asset('assets/icon/whats_icon.png')),
                        GestureDetector(
                            onTap: () {
                              _sendEmail('Info@doctak.net');
                            },
                            child: Image.asset('assets/icon/email.png')),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendEmail(String email) async {
    final Uri emailLaunchUri = Uri(
        scheme: 'mailto',
        path: email,
        queryParameters: {'subject': ''});
    if (await canLaunch(emailLaunchUri.toString())) {
      await launch(emailLaunchUri.toString());
    } else {
      throw 'Could not send email to $email';
    }
  }
}
