/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.mycompany.coretech3.controller;

/**
 *
 * @author kamil
 */
import com.mycompany.coretech3.service.AnalyticsService;
import java.util.List;
import javax.ejb.Stateless;
import javax.inject.Inject;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import org.json.JSONArray;
import org.json.JSONObject;

import com.mycompany.coretech3.service.AnalyticsService;
import java.util.List;
import javax.ejb.Stateless;
import javax.inject.Inject;
import javax.ws.rs.*;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import org.json.JSONArray;
import org.json.JSONObject;

@Stateless
@Path("admin/analytics")
@Produces(MediaType.APPLICATION_JSON)
public class AnalyticsController {

    @Inject
    private AnalyticsService analyticsService;

    // ================= TOTAL REVENUE =================
    @GET
    @Path("revenue")
    public Response getTotalRevenue() {
        try {
            long totalRevenue = analyticsService.getTotalRevenue();

            JSONObject resp = new JSONObject();
            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("totalRevenue", totalRevenue);

            return Response.ok(resp.toString()).build();
        } catch (Exception e) {
            e.printStackTrace();
            return error();
        }
    }

    // ================= TOTAL PROFIT =================
    @GET
    @Path("profit")
    public Response getTotalProfit() {
        try {
            long totalProfit = analyticsService.getTotalProfit();

            JSONObject resp = new JSONObject();
            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("totalProfit", totalProfit);

            return Response.ok(resp.toString()).build();
        } catch (Exception e) {
            e.printStackTrace();
            return error();
        }
    }

    // ================= USER SPENDING =================
    @GET
    @Path("user-spending")
    public Response getUserSpending() {
        try {
            List<Object[]> rows = analyticsService.getUserSpendings();
            JSONArray arr = new JSONArray();

            for (Object[] row : rows) {
                JSONObject obj = new JSONObject();
                obj.put("userId", row[0]);
                obj.put("username", row[1]);
                obj.put("email", row[2]);
                obj.put("totalSpent", row[3]);
                arr.put(obj);
            }

            JSONObject resp = new JSONObject();
            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("users", arr);

            return Response.ok(resp.toString()).build();
        } catch (Exception e) {
            e.printStackTrace();
            return error();
        }
    }

    // ================= ORDER COUNT =================
    @GET
    @Path("orders/count")
    public Response getOrdersCount() {
        try {
            long count = analyticsService.getTotalOrdersCount();

            JSONObject resp = new JSONObject();
            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("totalOrders", count);

            return Response.ok(resp.toString()).build();
        } catch (Exception e) {
            e.printStackTrace();
            return error();
        }
    }

    // ================= ORDER STATUS DISTRIBUTION =================
    @GET
    @Path("orders/status")
    public Response getOrderStatusDistribution() {
        try {
            List<Object[]> rows =
                    analyticsService.getOrderStatusDistribution();

            JSONArray arr = new JSONArray();
            for (Object[] row : rows) {
                JSONObject obj = new JSONObject();
                obj.put("status", row[0]);
                obj.put("count", row[1]);
                arr.put(obj);
            }

            JSONObject resp = new JSONObject();
            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("distribution", arr);

            return Response.ok(resp.toString()).build();
        } catch (Exception e) {
            e.printStackTrace();
            return error();
        }
    }

    // ================= ERROR HELPER =================
    private Response error() {
        JSONObject resp = new JSONObject();
        resp.put("status", "Error");
        resp.put("statusCode", 500);
        return Response.status(500).entity(resp.toString()).build();
    }
}