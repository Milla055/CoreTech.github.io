/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.mycompany.coretech3.security;

import io.jsonwebtoken.Claims;
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

    private static final String SECRET =
        System.getenv("JWT_SECRET");

    private static final long ACCESS_EXP =
        Long.parseLong(System.getenv("JWT_ACCESS_EXP"));

    private static final long REFRESH_EXP =
        Long.parseLong(System.getenv("JWT_REFRESH_EXP"));

    private static SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(SECRET.getBytes());
    }

    // 🔑 ACCESS TOKEN
    public static String generateAccessToken(
            String email, String role) {

        Date now = new Date();

        return Jwts.builder()
                .setSubject(email)
                .claim("role", role)
                .setIssuedAt(now)
                .setExpiration(
                    new Date(now.getTime() + ACCESS_EXP)
                )
                .signWith(getSigningKey(), SignatureAlgorithm.HS256)
                .compact();
    }

    // 🔁 REFRESH TOKEN
    public static String generateRefreshToken(Long userId) {

        Date now = new Date();

        return Jwts.builder()
                .claim("uid", userId)
                .setIssuedAt(now)
                .setExpiration(
                    new Date(now.getTime() + REFRESH_EXP)
                )
                .signWith(getSigningKey(), SignatureAlgorithm.HS256)
                .compact();
    }

    //  VALIDÁLÁS (mindkettőhöz)
    public static Claims validate(String token) {

        return Jwts.parserBuilder()
                .setSigningKey(getSigningKey())
                .build()
                .parseClaimsJws(token)
                .getBody();
    }
  
    
}
