/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.mycompany.coretech3.controller;

import com.mycompany.coretech3.service.OrdersService;
import javax.inject.Inject;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import org.json.JSONObject;

@Path("admin/orders")
@Produces(MediaType.APPLICATION_JSON)
public class AdminOrdersController {
    
    @Inject
    private OrdersService ordersService;
    
    // ========== GET ALL ORDERS ==========
    @GET
    public Response getAllOrders() {
        System.out.println("=== ADMIN GET ALL ORDERS CALLED ===");
        JSONObject result = ordersService.getAllOrders();
        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();
    }
    
    // ========== UPDATE ORDER STATUS ==========
    @PUT
    @Path("{orderId}/status")
    @Consumes(MediaType.APPLICATION_JSON)
    public Response updateOrderStatus(@PathParam("orderId") int orderId, String body) {
        System.out.println("=== ADMIN UPDATE ORDER STATUS CALLED: " + orderId + " ===");
        try {
            JSONObject obj = new JSONObject(body);
            String newStatus = obj.getString("status");
            
            JSONObject result = ordersService.updateOrderStatus(orderId, newStatus);
            
            return Response.status(result.getInt("statusCode"))
                    .entity(result.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
                    
        } catch (Exception e) {
            e.printStackTrace();
            JSONObject error = new JSONObject();
            error.put("status", "InvalidRequest");
            error.put("statusCode", 400);
            error.put("message", "Invalid request body");
            return Response.status(400)
                    .entity(error.toString())
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }
    }
    
    // ========== DELETE ORDER ==========
    @PUT
    @Path("delete/{orderId}")
    public Response deleteOrder(@PathParam("orderId") int orderId) {
        System.out.println("=== ADMIN DELETE ORDER CALLED: " + orderId + " ===");
        JSONObject result = ordersService.deleteOrderAdmin(orderId);
        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();
    }
}