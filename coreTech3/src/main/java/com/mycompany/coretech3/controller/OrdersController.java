package com.mycompany.coretech3.controller;

import com.mycompany.coretech3.security.JwtUtil;
import com.mycompany.coretech3.service.OrdersService;
import io.jsonwebtoken.Claims;
import javax.inject.Inject;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import org.json.JSONArray;
import org.json.JSONObject;

@Path("orders")
@Produces(MediaType.APPLICATION_JSON)
public class OrdersController {

    @Inject
    private OrdersService ordersService;

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    public Response createOrder(@HeaderParam("Authorization") String authHeader, String body) {
        System.out.println("=== CREATE ORDER CALLED ===");
        try {
            String token = authHeader.substring(7);
            Claims claims = JwtUtil.validate(token);
            int userId = claims.get("userId", Integer.class);

            JSONObject orderData = new JSONObject(body);
            JSONObject result = ordersService.createOrder(userId, orderData);

            return Response.status(result.getInt("statusCode"))
                    .entity(result.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();

        } catch (Exception e) {
            e.printStackTrace();
            JSONObject error = new JSONObject();
            error.put("status", "Error");
            error.put("statusCode", 400);
            error.put("message", e.getMessage());
            return Response.status(400)
                    .entity(error.toString())
                    .build();
        }
    }

    @GET
    public Response getMyOrders(@HeaderParam("Authorization") String authHeader) {
        System.out.println("=== GET MY ORDERS CALLED ===");
        try {
            // Extract userId from JWT
            String token = authHeader.substring(7);
            Claims claims = JwtUtil.validate(token);
            int userId = claims.get("userId", Integer.class);

            JSONObject result = ordersService.getOrdersByUserId(userId);

            return Response.status(result.getInt("statusCode"))
                    .entity(result.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();

        } catch (Exception e) {
            e.printStackTrace();
            JSONObject error = new JSONObject();
            error.put("status", "Unauthorized");
            error.put("statusCode", 401);
            error.put("message", "Invalid token: " + e.getMessage());
            return Response.status(401)
                    .entity(error.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }
    }

    @GET
    @Path("{orderId}")
    public Response getOrderById(@HeaderParam("Authorization") String authHeader,
            @PathParam("orderId") int orderId) {
        System.out.println("=== GET ORDER BY ID CALLED: " + orderId + " ===");
        try {
            // Extract userId from JWT
            String token = authHeader.substring(7);
            Claims claims = JwtUtil.validate(token);
            int userId = claims.get("userId", Integer.class);

            // Get order with ownership verification
            JSONObject result = ordersService.getOrderById(orderId, userId);

            return Response.status(result.getInt("statusCode"))
                    .entity(result.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();

        } catch (Exception e) {
            e.printStackTrace();
            JSONObject error = new JSONObject();
            error.put("status", "Unauthorized");
            error.put("statusCode", 401);
            error.put("message", "Invalid token: " + e.getMessage());
            return Response.status(401)
                    .entity(error.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }
    }

    @PUT
    @Path("delete/{orderId}")
    public Response deleteMyOrder(@HeaderParam("Authorization") String authHeader,
            @PathParam("orderId") int orderId) {
        System.out.println("=== DELETE MY ORDER CALLED: " + orderId + " ===");
        try {
            // Extract userId from JWT
            String token = authHeader.substring(7);
            Claims claims = JwtUtil.validate(token);
            int userId = claims.get("userId", Integer.class);

            // Delete order with ownership verification
            JSONObject result = ordersService.deleteMyOrder(orderId, userId);

            return Response.status(result.getInt("statusCode"))
                    .entity(result.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();

        } catch (Exception e) {
            e.printStackTrace();
            JSONObject error = new JSONObject();
            error.put("status", "Unauthorized");
            error.put("statusCode", 401);
            error.put("message", "Invalid token: " + e.getMessage());
            return Response.status(401)
                    .entity(error.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }
    }
    @POST
@Path("checkout")
@Consumes(MediaType.APPLICATION_JSON)
public Response checkout(@HeaderParam("Authorization") String authHeader, String body) {
    System.out.println("=== CHECKOUT CALLED ===");
    try {
        // Extract userId from JWT
        String token = authHeader.substring(7);
        Claims claims = JwtUtil.validate(token);
        int userId = claims.get("userId", Integer.class);
        
        // Parse request body
        JSONObject obj = new JSONObject(body);
        int addressId = obj.getInt("addressId");
        
        JSONObject result = ordersService.checkout(userId, addressId);
        
        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();
                
    } catch (Exception e) {
        e.printStackTrace();
        JSONObject error = new JSONObject();
        error.put("status", "Error");
        error.put("statusCode", 400);
        error.put("message", "Invalid request: " + e.getMessage());
        return Response.status(400)
                .entity(error.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();
    }
}
}
