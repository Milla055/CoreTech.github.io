/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.mycompany.coretech3.service;

import jakarta.activation.DataHandler;
import jakarta.activation.DataSource;
import jakarta.activation.FileDataSource;
import jakarta.mail.Authenticator;
import jakarta.mail.Message;
import jakarta.mail.MessagingException;
import jakarta.mail.Multipart;
import jakarta.mail.PasswordAuthentication;
import jakarta.mail.Session;
import jakarta.mail.Transport;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeBodyPart;
import jakarta.mail.internet.MimeMessage;
import jakarta.mail.internet.MimeMultipart;
import jakarta.mail.util.ByteArrayDataSource;
import java.io.InputStream;
import java.util.Properties;

/**
 *
 * @author kamil
 */
public class EmailService {

    private static final String USERNAME = "coretech112@gmail.com";
    private static final String APP_PASSWORD = "tmcg pxgh gaju gkzh";


    public static void sendEmail(String to, String subject, String htmlContent) {

        try {
            Message message = buildBasicMessage(to, subject);

            // sima HTML content
            message.setContent(htmlContent, "text/html; charset=UTF-8");

            Transport.send(message);
            System.out.println("Email elküldve: " + to);

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    // ==========================================================
    // 2) HTML EMAIL INLINE KÉPPEL
    // ==========================================================
    public static void sendEmailWithImage(String to, String subject, String htmlContent, String imageName) {
    try {
        Properties props = new Properties();
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.starttls.enable", "true");
        props.put("mail.smtp.host", "smtp.gmail.com");
        props.put("mail.smtp.port", "587");

        Session session = Session.getInstance(props, new jakarta.mail.Authenticator() {
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(USERNAME, APP_PASSWORD);
            }
        });

        MimeMessage message = new MimeMessage(session);
        message.setFrom(new InternetAddress(USERNAME));
        message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(to));
        message.setSubject(subject, "UTF-8");

        // HTML rész
        MimeBodyPart htmlPart = new MimeBodyPart();
        htmlPart.setContent(htmlContent, "text/html; charset=UTF-8");

        // --- ÍGY TÖLTJÜK A KÉPET A WAR-BÓL ---
        InputStream imgStream = EmailService.class
                .getClassLoader()
                .getResourceAsStream("email/" + imageName);

        if (imgStream == null) {
            System.err.println("❌ KÉP NEM TALÁLHATÓ: email/" + imageName);
            return;
        }

        MimeBodyPart imgPart = new MimeBodyPart();
        DataSource fds = new ByteArrayDataSource(imgStream, "image/png");
        imgPart.setDataHandler(new DataHandler(fds));
        imgPart.setHeader("Content-ID", "<checkmark>");
        imgPart.setDisposition(MimeBodyPart.INLINE);

        Multipart multipart = new MimeMultipart();
        multipart.addBodyPart(htmlPart);
        multipart.addBodyPart(imgPart);

        message.setContent(multipart);

        Transport.send(message);

        System.out.println("✔ Inline képes email elküldve → " + to);

    } catch (Exception e) {
        e.printStackTrace();
    }
}

    // ==========================================================
    // SEGÉD: SMTP SESSION + basic message builder
    // ==========================================================
    private static Message buildBasicMessage(String to, String subject) throws MessagingException {
        Properties props = new Properties();

        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.starttls.enable", "true");
        props.put("mail.smtp.host", "smtp.gmail.com");
        props.put("mail.smtp.port", "587");

        Session session = Session.getInstance(props, new Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(USERNAME, APP_PASSWORD);
            }
        });

        Message message = new MimeMessage(session);
        message.setFrom(new InternetAddress(USERNAME, false));
        message.setRecipient(Message.RecipientType.TO, new InternetAddress(to));
        message.setSubject(subject);

        return message;
    }
}
