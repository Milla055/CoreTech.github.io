package com.mycompany.coretech3.util;

import java.io.InputStream;
import java.util.Properties;

public class ImageConfig {
    private static String basePath;
    
    static {
        try {
            Properties props = new Properties();
            InputStream input = ImageConfig.class.getClassLoader()
                    .getResourceAsStream("images.properties");
            props.load(input);
            basePath = props.getProperty("images.basePath");
            System.out.println(" Images base path loaded: " + basePath);
        } catch (Exception e) {
            System.err.println(" Failed to load images.properties, using default");
            basePath = "/Users/markbajor/Downloads/wildfly-preview-26.1.1.Final/domain/tmp";
        }
    }
    
    public static String getBasePath() {
        return basePath;
    }
}
