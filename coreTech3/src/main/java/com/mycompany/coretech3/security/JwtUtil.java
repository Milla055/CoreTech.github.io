/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.mycompany.coretech3.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import javax.crypto.SecretKey;
import java.io.IOException;
import java.io.InputStream;
import java.util.Date;
import java.util.Properties;

public class JwtUtil {
    private static final String SECRET;
    private static final long ACCESS_EXP;
    private static final long REFRESH_EXP;
    
    // Static blokk - betölti a properties fájlt egyszer, amikor az osztály betöltődik
    static {
        Properties props = new Properties();
        
        try (InputStream input = JwtUtil.class
                .getClassLoader()
                .getResourceAsStream("jwt.properties")) {
            
            if (input == null) {
                System.err.println("Nem található a jwt.properties fájl!");
                throw new RuntimeException("jwt.properties not found");
            }
            
            props.load(input);
            System.out.println(" jwt.properties sikeresen betöltve!");
            
        } catch (IOException e) {
            System.err.println("Hiba a jwt.properties betöltésekor!");
            e.printStackTrace();
            throw new RuntimeException("Failed to load jwt.properties", e);
        }
        
        // Értékek kiolvasása
        SECRET = props.getProperty("jwt.secret");
        ACCESS_EXP = Long.parseLong(props.getProperty("jwt.access.exp"));
        REFRESH_EXP = Long.parseLong(props.getProperty("jwt.refresh.exp"));
        
        // Ellenőrzés
        if (SECRET == null || SECRET.isEmpty()) {
            throw new RuntimeException("jwt.secret is missing!");
        }
        
        System.out.println(" JWT Secret betöltve, hossz: " + SECRET.length() + " karakter");
        System.out.println("️ Access token exp: " + (ACCESS_EXP / 1000 / 60) + " perc");
        System.out.println("️ Refresh token exp: " + (REFRESH_EXP / 1000 / 60 / 60 / 24) + " nap");
    }
    
    private static SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(SECRET.getBytes());
    }
    
    public static String generateAccessToken(String email, String role, Long userId) {
    Date now = new Date();
    return Jwts.builder()
            .setSubject(email)
            .claim("role", role)
            .claim("userId", userId)  //idkell
            .setIssuedAt(now)
            .setExpiration(new Date(now.getTime() + ACCESS_EXP))
            .signWith(getSigningKey(), SignatureAlgorithm.HS256)
            .compact();
}
    
    public static String generateRefreshToken(Long userId) {
        Date now = new Date();
        return Jwts.builder()
                .claim("userId", userId)
                .setIssuedAt(now)
                .setExpiration(new Date(now.getTime() + REFRESH_EXP))
                .signWith(getSigningKey(), SignatureAlgorithm.HS256)
                .compact();
    }
    
    public static Claims validate(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(getSigningKey())
                .build()
                .parseClaimsJws(token)
                .getBody();
    }
}
