
package com.mycompany.coretech3.security;

import io.jsonwebtoken.Claims;
import javax.annotation.Priority;
import javax.ws.rs.Priorities;
import javax.ws.rs.container.ContainerRequestContext;
import javax.ws.rs.container.ContainerRequestFilter;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.Response;
import javax.ws.rs.ext.Provider;

@Provider
@Priority(Priorities.AUTHENTICATION)
public class JwtAuthFilter implements ContainerRequestFilter {

    @Override
    public void filter(ContainerRequestContext ctx) {

        String path = ctx.getUriInfo().getPath();
        System.out.println("JWT FILTER PATH = " + path);

        if (path.contains("Users/login")
                || path.contains("Users/refresh")
                || path.contains("Users/createUser")) {
            System.out.println(" PUBLIC USER ENDPOINT - ALLOWED");
            return;
        }

        if ((path.equals("products") || path.equals("/products")
                || path.startsWith("products/") || path.startsWith("/products/"))
                && !path.contains("admin")) {
            System.out.println(" PUBLIC PRODUCT ENDPOINT - ALLOWED");
            return;
        }

        if (path.contains("categories") && !path.contains("admin")) {
            return;
        }
        if (path.contains("brands") && !path.contains("admin")) {
            return;
        }
        // Public questionnaire endpoints
        if (path.contains("questionnaire")) {
            System.out.println(" PUBLIC QUESTIONNAIRE ENDPOINT - ALLOWED");
            return;
        }

        System.out.println(" PROTECTED ENDPOINT - JWT REQUIRED");

        String auth = ctx.getHeaderString(HttpHeaders.AUTHORIZATION);

        if (auth == null || !auth.startsWith("Bearer ")) {
            ctx.abortWith(
                    Response.status(401)
                            .entity("Missing or invalid Authorization header")
                            .build()
            );
            return;
        }

        String token = auth.substring(7);

        try {
            Claims claims = JwtUtil.validate(token);
            String role = claims.get("role", String.class);

            //  ADMIN védelem
            if (path.contains("admin")
                    && !"admin".equalsIgnoreCase(role)) {

                ctx.abortWith(
                        Response.status(403)
                                .entity("Admin only")
                                .build()
                );
            }

        } catch (Exception e) {
            ctx.abortWith(
                    Response.status(401)
                            .entity("Invalid or expired token")
                            .build()
            );
        }
    }
}
