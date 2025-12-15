/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.mycompany.coretech3.security;

import io.jsonwebtoken.Claims;
import javax.annotation.Priority;
import javax.ws.rs.Priorities;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerRequestFilter;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.Response;
import javax.ws.rs.ext.Provider;

/**
 *
 * @author kamil
 */
@Provider
@Priority(Priorities.AUTHENTICATION)
public class JwtAuthFilter implements ContainerRequestFilter {

    @Override
    public void filter(ContainerRequestContext ctx) {

        String path = ctx.getUriInfo().getPath();

        // PUBLIC ENDPOINTS
        if (path.startsWith("Users/login")
            || path.startsWith("Users/refresh")
            || path.startsWith("Users/create")) {
            return;
        }

        String auth = ctx.getHeaderString(HttpHeaders.AUTHORIZATION);

        if (auth == null || !auth.startsWith("Bearer ")) {
            ctx.abortWith(Response.status(401).build());
            return;
        }

        String token = auth.substring(7);

        try {
            Claims claims = JwtUtil.validate(token);
            String role = claims.get("role", String.class);

            // ADMIN védelem
            if (path.startsWith("admin") &&
                !"admin".equalsIgnoreCase(role)) {

                ctx.abortWith(Response.status(403).build());
            }

        } catch (Exception e) {
            ctx.abortWith(Response.status(401).build());
        }
    }
}
