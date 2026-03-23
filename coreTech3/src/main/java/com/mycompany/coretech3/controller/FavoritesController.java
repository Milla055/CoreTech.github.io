package com.mycompany.coretech3.controller;

import com.mycompany.coretech3.security.JwtUtil;
import com.mycompany.coretech3.service.FavoritesService;
import io.jsonwebtoken.Claims;
import javax.inject.Inject;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import org.json.JSONObject;

@Path("favorites")
@Produces(MediaType.APPLICATION_JSON)
public class FavoritesController {
    
    @Inject
    private FavoritesService favoritesService;
    
    
    @POST
    @Path("{productId}")
    public Response addToFavorites(@HeaderParam("Authorization") String authHeader,
                                   @PathParam("productId") int productId) {
        System.out.println("=== ADD TO FAVORITES CALLED: Product " + productId + " ===");
        try {
            // Extract userId from JWT
            String token = authHeader.substring(7);
            Claims claims = JwtUtil.validate(token);
            int userId = claims.get("userId", Integer.class);
            
            JSONObject result = favoritesService.addToFavorites(userId, productId);
            
            return Response.status(result.getInt("statusCode"))
                    .entity(result.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
                    
        } catch (Exception e) {
            e.printStackTrace();
            JSONObject error = new JSONObject();
            error.put("status", "Unauthorized");
            error.put("statusCode", 401);
            error.put("message", "Invalid token");
            return Response.status(401)
                    .entity(error.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }
    }
    

    @PUT
    @Path("{productId}")
    public Response removeFromFavorites(@HeaderParam("Authorization") String authHeader,
                                        @PathParam("productId") int productId) {
        System.out.println("=== REMOVE FROM FAVORITES CALLED: Product " + productId + " ===");
        try {
            // Extract userId from JWT
            String token = authHeader.substring(7);
            Claims claims = JwtUtil.validate(token);
            int userId = claims.get("userId", Integer.class);
            
            JSONObject result = favoritesService.removeFromFavorites(userId, productId);
            
            return Response.status(result.getInt("statusCode"))
                    .entity(result.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
                    
        } catch (Exception e) {
            e.printStackTrace();
            JSONObject error = new JSONObject();
            error.put("status", "Unauthorized");
            error.put("statusCode", 401);
            error.put("message", "Invalid token");
            return Response.status(401)
                    .entity(error.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }
    }
    
   
    @GET
    public Response getMyFavorites(@HeaderParam("Authorization") String authHeader) {
        System.out.println("=== GET MY FAVORITES CALLED ===");
        try {
            // Extract userId from JWT
            String token = authHeader.substring(7);
            Claims claims = JwtUtil.validate(token);
            int userId = claims.get("userId", Integer.class);
            
            JSONObject result = favoritesService.getMyFavorites(userId);
            
            return Response.status(result.getInt("statusCode"))
                    .entity(result.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
                    
        } catch (Exception e) {
            e.printStackTrace();
            JSONObject error = new JSONObject();
            error.put("status", "Unauthorized");
            error.put("statusCode", 401);
            error.put("message", "Invalid token");
            return Response.status(401)
                    .entity(error.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }
    }
}