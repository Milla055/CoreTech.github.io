/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.mycompany.coretech3.util;

/**
 *
 * @author kamil
 */
import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.stream.Collectors;

public class EmailTemplateLoader {

    public static String loadTemplate(String fileName) {
        try {
            InputStream is = EmailTemplateLoader.class.getClassLoader()
                    .getResourceAsStream("email/" + fileName);

            if (is == null) {
                throw new RuntimeException("Email template not found: " + fileName);
            }

            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(is, StandardCharsets.UTF_8))) {

                return reader.lines().collect(Collectors.joining("\n"));
            }

        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }
}
