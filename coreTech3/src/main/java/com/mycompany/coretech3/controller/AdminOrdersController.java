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
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import org.json.JSONObject;

@Stateless
@Path("admin/orders")
public class AdminOrdersController {

    @Inject
    private AdminOrdersService adminOrdersService;

    @PersistenceContext(unitName = "com.mycompany_coreTech3_war_1.0-SNAPSHOTPU")
    private EntityManager em;

    // ================= ADMIN CHECK =================
    private boolean isAdmin(int adminId) {
        Users admin = em.find(Users.class, adminId);
        return admin != null && "admin".equalsIgnoreCase(admin.getRole());
    }

    private Response forbidden() {
        return Response.status(403)
                .entity("{\"status\":\"Forbidden - Admin only\",\"statusCode\":403}")
                .build();
    }

    // ================= GET ALL ORDERS =================
    @GET
    @Path("all/{adminId}")
    @Produces(MediaType.APPLICATION_JSON)
    public Response getAllOrders(@PathParam("adminId") int adminId) {

        if (!isAdmin(adminId)) {
            return forbidden();
        }

        JSONObject result = adminOrdersService.getAllOrders();

        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .build();
    }

    // ================= GET ORDER BY ID =================
    @GET
    @Path("get/{adminId}/{orderId}")
    @Produces(MediaType.APPLICATION_JSON)
    public Response getOrderById(
            @PathParam("adminId") int adminId,
            @PathParam("orderId") int orderId) {

        if (!isAdmin(adminId)) {
            return forbidden();
        }

        JSONObject result = adminOrdersService.getOrderById(orderId);

        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .build();
    }

    // ================= UPDATE STATUS =================
    @PUT
    @Path("status/{adminId}")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response updateStatus(
            @PathParam("adminId") int adminId,
            String body) {

        if (!isAdmin(adminId)) {
            return forbidden();
        }

        JSONObject obj = new JSONObject(body);

        int orderId = obj.getInt("orderId");
        String newStatus = obj.getString("newStatus");

        JSONObject result = adminOrdersService.updateOrderStatus(orderId, newStatus);

        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .build();
    }

    // ================= SOFT DELETE ORDER =================
    @PUT
    @Path("delete/{adminId}/{orderId}")
    @Produces(MediaType.APPLICATION_JSON)
    public Response deleteOrder(
            @PathParam("adminId") int adminId,
            @PathParam("orderId") int orderId) {

        if (!isAdmin(adminId)) {
            return forbidden();
        }

        JSONObject result = adminOrdersService.softDeleteOrder(orderId);

        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .build();
    }

    // ================= GET USER'S ORDERS (ADMIN SIDE) =================
    @GET
    @Path("user/{adminId}/{userId}")
    @Produces(MediaType.APPLICATION_JSON)
    public Response getOrdersByUser(
            @PathParam("adminId") int adminId,
            @PathParam("userId") int userId) {

        if (!isAdmin(adminId)) {
            return forbidden();
        }

        JSONObject result = adminOrdersService.getOrdersByUserAdmin(userId);

        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .build();
    }
}
