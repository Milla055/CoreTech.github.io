/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.mycompany.coreTech2.security;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import java.util.Date;
import javax.crypto.SecretKey;

/**
 *
 * @author kamil
 */
public class JwtUtil {
    

    // Minimum 32 karakter !!!
    private static final String SECRET = "THIS_IS_A_REALLY_LONG_SECRET_KEY_1234567890";
    private static final long EXPIRATION_MS = 1000L * 60 * 60; // 1 óra

    private static SecretKey getSigningKey() {
        // EZ FONTOS: byte[] -> SecretKey
        return Keys.hmacShaKeyFor(SECRET.getBytes());
    }

    public static String generateToken(String email) {
        Date now = new Date();
        Date expiry = new Date(now.getTime() + EXPIRATION_MS);

        return Jwts.builder()
                .setSubject(email)           // token tulajdonosa
                .setIssuedAt(now)            // kiadás idő
                .setExpiration(expiry)       // lejárat
                .signWith(getSigningKey(), SignatureAlgorithm.HS256)
                .compact();
    }
}


