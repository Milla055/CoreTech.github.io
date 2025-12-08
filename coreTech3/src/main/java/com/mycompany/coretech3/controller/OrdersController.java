/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.mycompany.coretech3.controller;

/**
 *
 * @author kamil
 */
import com.mycompany.coretech3.service.OrdersService;
import javax.ejb.Stateless;
import javax.inject.Inject;
import javax.ws.rs.Consumes;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import org.json.JSONObject;

@Stateless
@Path("orders")
public class OrdersController {
    @Inject
    private OrdersService ordersService;

    @POST
    @Path("createOrder")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public Response createOrder(String body) {

        JSONObject obj = new JSONObject(body);

        int userId = obj.getInt("userId");
        int addressId = obj.getInt("addressId");
        String totalPrice = obj.getString("totalPrice");
        String status = obj.has("status") ? obj.getString("status") : "pending";

        JSONObject result = ordersService.createOrder(userId, addressId, totalPrice, status);

        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .build();
    }



//    @GET
//    @Path("autoprogress")
//    @Produces(MediaType.APPLICATION_JSON)
//    public Response autoProgressOrders() {
//        ordersService.autoProgressOrders();
//
//        JSONObject resp = new JSONObject();
//        resp.put("status", "OrdersProgressed");
//        resp.put("statusCode", 200);
//
//        return Response.ok(resp.toString()).build();
//    }

    @GET
    @Path("user/{userId}")
    @Produces(MediaType.APPLICATION_JSON)
    public Response getOrdersByUser(@PathParam("userId") int userId) {

        JSONObject result = ordersService.getOrdersByUserId(userId);

        return Response.status(result.getInt("statusCode"))
                .entity(result.toString())
                .type(MediaType.APPLICATION_JSON)
                .build();
    }
}

