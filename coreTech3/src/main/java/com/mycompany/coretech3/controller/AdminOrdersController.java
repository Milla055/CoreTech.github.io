/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.mycompany.coretech3.controller;

import com.mycompany.coretech3.model.Users;
import javax.ws.rs.Consumes;
import javax.ws.rs.GET;
import javax.ws.rs.PUT;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import com.mycompany.coretech3.service.AdminOrdersService;
import javax.ejb.Stateless;
import javax.inject.Inject;
import javax.persistence.PersistenceContext;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import org.json.JSONObject;

@Stateless
@Path("admin/orders")
@Produces(MediaType.APPLICATION_JSON)
public class AdminOrdersController {

    @Inject
    private AdminOrdersService adminOrdersService;

    // ================= GET ALL ORDERS =================
    @GET
    public Response getAllOrders() {

        JSONObject result = adminOrdersService.getAllOrders();

        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .build();
    }

    // ================= GET ORDER BY ID =================
    @GET
    @Path("{orderId}")
    public Response getOrderById(
            @PathParam("orderId") int orderId) {

        JSONObject result = adminOrdersService.getOrderById(orderId);

        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .build();
    }

    // ================= UPDATE STATUS =================
    @PUT
    @Path("status")
    @Consumes(MediaType.APPLICATION_JSON)
    public Response updateStatus(String body) {

        JSONObject obj = new JSONObject(body);

        int orderId = obj.getInt("orderId");
        String newStatus = obj.getString("newStatus");

        JSONObject result =
                adminOrdersService.updateOrderStatus(orderId, newStatus);

        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .build();
    }

    // ================= SOFT DELETE ORDER =================
    @PUT
    @Path("delete/{orderId}")
    public Response deleteOrder(
            @PathParam("orderId") int orderId) {

        JSONObject result =
                adminOrdersService.softDeleteOrder(orderId);

        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .build();
    }

    // ================= GET USER'S ORDERS =================
    @GET
    @Path("user/{userId}")
    public Response getOrdersByUser(
            @PathParam("userId") int userId) {

        JSONObject result =
                adminOrdersService.getOrdersByUserAdmin(userId);

        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .build();
    }
}