package com.mycompany.coretech3.controller;

import com.mycompany.coretech3.model.Users;
import com.mycompany.coretech3.security.JwtUtil;
import com.mycompany.coretech3.service.UsersService;
import io.jsonwebtoken.Claims;
import javax.inject.Inject;
import javax.persistence.EntityManager;
import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.Consumes;
import javax.ws.rs.CookieParam;
import javax.ws.rs.HeaderParam;
import javax.ws.rs.POST;
import javax.ws.rs.PUT;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.Cookie;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.NewCookie;
import javax.ws.rs.core.Response;
import org.json.JSONObject;

/**
 *
 * @author kamil
 */
@Path("Users")
public class UsersController {

    @Inject   // ← CDI injektálja a UsersService EJB-t
    private UsersService usersService;
    private EntityManager em;

    @POST
    @Path("createUser")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response createUser(String body) {
        JSONObject obj = new JSONObject(body);

        String username = obj.getString("username");
        String email = obj.getString("email");
        String phone = obj.getString("phone");
        String password = obj.getString("password");
        String role = obj.has("role") ? obj.getString("role") : null;

        JSONObject result = usersService.createUser(username, email, phone, password, role);

        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();

    }

    @PUT
    @Path("softDeleteUser")
    @Produces(MediaType.APPLICATION_JSON)
    public Response softDeleteUser(@HeaderParam("Authorization") String authHeader) {
        try {
            // Extract and validate token
            String token = authHeader.substring(7); // Remove "Bearer "
            Claims claims = JwtUtil.validate(token);

            // Get userId from token
            int userId = claims.get("userId", Integer.class);

            // Call service
            JSONObject result = usersService.softDeleteUser(userId);

            return Response.status(result.getInt("statusCode"))
                    .entity(result.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();

        } catch (Exception e) {
            e.printStackTrace();
            JSONObject error = new JSONObject();
            error.put("status", "Error");
            error.put("statusCode", 401);
            error.put("message", "Invalid token");
            return Response.status(401)
                    .entity(error.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }
    }

    @PUT
    @Path("updateUser")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response updateUser(@HeaderParam("Authorization") String authHeader, String body) {
        try {
            String token = authHeader.substring(7);
            Claims claims = JwtUtil.validate(token);
            int userId = claims.get("userId", Integer.class);

            JSONObject obj = new JSONObject(body);
            String email = obj.getString("email");
            String phone = obj.getString("phone");

            JSONObject result = usersService.updateUser(userId, email, phone);

            return Response.status(result.getInt("statusCode"))
                    .entity(result.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();

        } catch (Exception e) {
            e.printStackTrace(); // ⚠️ Check server console for this error!
            JSONObject error = new JSONObject();
            error.put("status", "Error");
            error.put("statusCode", 401);
            error.put("message", "Invalid token");
            return Response.status(401)
                    .entity(error.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }
    }

    @PUT
    @Path("changePassword")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response changePassword(@HeaderParam("Authorization") String authHeader, String body) {
        try {
            // Extract and validate token
            String token = authHeader.substring(7); // Remove "Bearer "
            Claims claims = JwtUtil.validate(token);

            // Get userId from token
            int userId = claims.get("userId", Integer.class);

            // Parse request body for old and new passwords
            JSONObject obj = new JSONObject(body);
            String oldPassword = obj.getString("oldPassword");
            String newPassword = obj.getString("newPassword");

            // Validate input
            if (oldPassword == null || oldPassword.isEmpty()) {
                JSONObject error = new JSONObject();
                error.put("status", "Error");
                error.put("statusCode", 400);
                error.put("message", "Old password is required");
                return Response.status(400)
                        .entity(error.toString())
                        .type(MediaType.APPLICATION_JSON)
                        .build();
            }

            if (newPassword == null || newPassword.isEmpty() || newPassword.length() < 6) {
                JSONObject error = new JSONObject();
                error.put("status", "Error");
                error.put("statusCode", 400);
                error.put("message", "New password must be at least 6 characters");
                return Response.status(400)
                        .entity(error.toString())
                        .type(MediaType.APPLICATION_JSON)
                        .build();
            }

            // Call service to change password (service will verify old password)
            JSONObject result = usersService.changePassword(userId, oldPassword, newPassword);

            return Response.status(result.getInt("statusCode"))
                    .entity(result.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();

        } catch (Exception e) {
            e.printStackTrace();
            JSONObject error = new JSONObject();
            error.put("status", "Error");
            error.put("statusCode", 401);
            error.put("message", "Invalid token or request");
            return Response.status(401)
                    .entity(error.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }
    }

    @POST
    @Path("login")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response login(String body) {
        JSONObject obj = new JSONObject(body);
        String email = obj.getString("email");
        String password = obj.getString("password");

        JSONObject result = usersService.login(email, password);

        if (result.getInt("statusCode") == 200) {
            String refreshToken = result.getString("refreshToken");

            // Remove refreshToken from JSON response
            result.remove("refreshToken");

            // Set refreshToken as HttpOnly cookie
            NewCookie cookie = new NewCookie(
                    "refreshToken", // name
                    refreshToken, // value
                    "/", // path
                    null, // domain
                    null, // comment
                    7 * 24 * 60 * 60, // maxAge (7 days)
                    false, // secure (use true in production with HTTPS)
                    true // httpOnly
            );

            return Response.status(result.getInt("statusCode"))
                    .entity(result.toString())
                    .cookie(cookie)
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }

        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();

    }

//    @POST
//@Path("refresh")
//@Produces(MediaType.APPLICATION_JSON)
//public Response refresh(@CookieParam("refreshToken") String refreshToken) {
//    System.out.println("=== REFRESH ENDPOINT CALLED ===");
//    System.out.println("refreshToken from cookie: " + refreshToken);
//    
//    if (refreshToken == null) {
//        System.out.println("ERROR: refreshToken is NULL!");
//        JSONObject error = new JSONObject();
//        error.put("status", "MissingRefreshToken");
//        error.put("statusCode", 401);
//        return Response.status(401)
//                .entity(error.toString())
//                .type(MediaType.APPLICATION_JSON)
//                .build();
//    }
//    
//    try {
//        Claims claims = JwtUtil.validate(refreshToken);
//        Long userId = claims.get("uid", Long.class);
//        System.out.println("userId from token: " + userId);
//        
//        // Use service - pass userId.intValue() as parameter
//        Users user = usersService.getUserById(userId.intValue());
//        
//        if (user == null || Boolean.TRUE.equals(user.getIsDeleted())) {
//            System.out.println("ERROR: User not found or deleted");
//            JSONObject error = new JSONObject();
//            error.put("status", "UserNotFoundOrDeleted");
//            error.put("statusCode", 401);
//            return Response.status(401)
//                    .entity(error.toString())
//                    .type(MediaType.APPLICATION_JSON)
//                    .build();
//        }
//        
//        String newAccessToken = JwtUtil.generateAccessToken(
//                user.getEmail(),
//                user.getRole(),
//                Long.valueOf(user.getId())
//        );
//        
//        JSONObject resp = new JSONObject();
//        resp.put("status", "TokenRefreshed");
//        resp.put("statusCode", 200);
//        resp.put("accessToken", newAccessToken);
//        
//        System.out.println("SUCCESS: New access token generated");
//        return Response.status(200)
//                .entity(resp.toString())
//                .type(MediaType.APPLICATION_JSON)
//                .build();
//                
//    } catch (Exception e) {
//        System.out.println("ERROR: Exception during refresh - " + e.getMessage());
//        e.printStackTrace();
//        JSONObject error = new JSONObject();
//        error.put("status", "InvalidRefreshToken");
//        error.put("statusCode", 401);
//        return Response.status(401)
//                .entity(error.toString())
//                .type(MediaType.APPLICATION_JSON)
//                .build();
//    }
//}
    @POST
    @Path("logout")
    public Response logout() {

        NewCookie deleteCookie = new NewCookie(
                "refreshToken", "",
                "/", null,
                "logout",
                0,
                false,
                true
        );

        return Response.ok()
                .cookie(deleteCookie)
                .build();
    }

}
