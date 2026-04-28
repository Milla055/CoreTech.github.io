
package com.mycompany.coretech3.controller;


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

    // ================= DASHBOARD SUMMARY (minden adat egyben) =================
    @GET
    @Path("dashboard")
    public Response getDashboardSummary() {
        try {
            Object[] summary = analyticsService.getDashboardSummary();

            JSONObject resp = new JSONObject();
            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("totalCustomers", ((Number) summary[0]).longValue());
            resp.put("totalOrders", ((Number) summary[1]).longValue());
            resp.put("totalRevenue", ((Number) summary[2]).longValue());
            resp.put("totalProfit", ((Number) summary[3]).longValue());

            return Response.ok(resp.toString()).build();
        } catch (Exception e) {
            e.printStackTrace();
            return error("Error fetching dashboard summary: " + e.getMessage());
        }
    }

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
            return error("Error calculating revenue: " + e.getMessage());
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
            return error("Error calculating profit: " + e.getMessage());
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
                obj.put("totalSpent", ((Number) row[3]).longValue());
                arr.put(obj);
            }

            JSONObject resp = new JSONObject();
            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("users", arr);

            return Response.ok(resp.toString()).build();
        } catch (Exception e) {
            e.printStackTrace();
            return error("Error fetching user spending: " + e.getMessage());
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
            return error("Error counting orders: " + e.getMessage());
        }
    }

    // ================= ORDER STATUS DISTRIBUTION =================
    @GET
    @Path("orders/status")
    public Response getOrderStatusDistribution() {
        try {
            List<Object[]> rows = analyticsService.getOrderStatusDistribution();

            JSONArray arr = new JSONArray();
            for (Object[] row : rows) {
                JSONObject obj = new JSONObject();
                obj.put("status", row[0]);
                obj.put("count", ((Number) row[1]).longValue());
                arr.put(obj);
            }

            JSONObject resp = new JSONObject();
            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("distribution", arr);

            return Response.ok(resp.toString()).build();
        } catch (Exception e) {
            e.printStackTrace();
            return error("Error fetching order status distribution: " + e.getMessage());
        }
    }

    // ================= MONTHLY SALES STATS (diagramhoz) =================
    @GET
    @Path("monthly-sales")
    public Response getMonthlySalesStats() {
        try {
            List<Object[]> rows = analyticsService.getMonthlySalesStats();
            JSONArray arr = new JSONArray();

            // Hónap nevek a frontend számára
            String[] monthNames = {"", "Jan", "Feb", "Már", "Ápr", "Máj", "Jún", 
                                   "Júl", "Aug", "Szep", "Okt", "Nov", "Dec"};

            for (Object[] row : rows) {
                JSONObject obj = new JSONObject();
                int monthNum = ((Number) row[0]).intValue();
                
                obj.put("month", monthNum);
                obj.put("monthName", monthNames[monthNum]);
                obj.put("year", ((Number) row[1]).intValue());
                
                // Bevétel ezer forintban (K Ft)
                long revenueInHuf = ((Number) row[2]).longValue();
                obj.put("revenue", revenueInHuf);
                obj.put("revenueInK", revenueInHuf / 1000.0);
                
                obj.put("orderCount", ((Number) row[3]).longValue());
                arr.put(obj);
            }

            JSONObject resp = new JSONObject();
            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("monthlyStats", arr);

            return Response.ok(resp.toString()).build();
        } catch (Exception e) {
            e.printStackTrace();
            return error("Error fetching monthly sales stats: " + e.getMessage());
        }
    }

    // ================= MONTHLY PROFIT STATS =================
    @GET
    @Path("monthly-profit")
    public Response getMonthlyProfitStats() {
        try {
            List<Object[]> rows = analyticsService.getMonthlyProfitStats();
            JSONArray arr = new JSONArray();

            String[] monthNames = {"", "Jan", "Feb", "Már", "Ápr", "Máj", "Jún", 
                                   "Júl", "Aug", "Szep", "Okt", "Nov", "Dec"};

            for (Object[] row : rows) {
                JSONObject obj = new JSONObject();
                int monthNum = ((Number) row[0]).intValue();
                
                obj.put("month", monthNum);
                obj.put("monthName", monthNames[monthNum]);
                obj.put("year", ((Number) row[1]).intValue());
                
                long profitInHuf = ((Number) row[2]).longValue();
                obj.put("profit", profitInHuf);
                obj.put("profitInK", profitInHuf / 1000.0);
                
                arr.put(obj);
            }

            JSONObject resp = new JSONObject();
            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("monthlyProfitStats", arr);

            return Response.ok(resp.toString()).build();
        } catch (Exception e) {
            e.printStackTrace();
            return error("Error fetching monthly profit stats: " + e.getMessage());
        }
    }

    // ================= TOTAL CUSTOMERS =================
    @GET
    @Path("customers/count")
    public Response getTotalCustomers() {
        try {
            long count = analyticsService.getTotalCustomers();

            JSONObject resp = new JSONObject();
            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("totalCustomers", count);

            return Response.ok(resp.toString()).build();
        } catch (Exception e) {
            e.printStackTrace();
            return error("Error counting customers: " + e.getMessage());
        }
    }

    // ================= TOTAL PURCHASES =================
    @GET
    @Path("purchases/count")
    public Response getTotalPurchases() {
        try {
            long count = analyticsService.getTotalPurchases();

            JSONObject resp = new JSONObject();
            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("totalPurchases", count);

            return Response.ok(resp.toString()).build();
        } catch (Exception e) {
            e.printStackTrace();
            return error("Error counting purchases: " + e.getMessage());
        }
    }

    // ================= TOP PRODUCTS =================
    @GET
    @Path("top-products")
    public Response getTopProducts() {
        try {
            List<Object[]> rows = analyticsService.getTopProducts();
            JSONArray arr = new JSONArray();

            for (Object[] row : rows) {
                JSONObject obj = new JSONObject();
                obj.put("productId", row[0]);
                obj.put("productName", row[1]);
                obj.put("totalSold", ((Number) row[2]).longValue());
                obj.put("totalRevenue", ((Number) row[3]).longValue());
                arr.put(obj);
            }

            JSONObject resp = new JSONObject();
            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("topProducts", arr);

            return Response.ok(resp.toString()).build();
        } catch (Exception e) {
            e.printStackTrace();
            return error("Error fetching top products: " + e.getMessage());
        }
    }

    // ================= ERROR HELPER =================
    private Response error() {
        return error("Internal server error");
    }

    private Response error(String message) {
        JSONObject resp = new JSONObject();
        resp.put("status", "Error");
        resp.put("statusCode", 500);
        resp.put("message", message);
        return Response.status(500).entity(resp.toString()).build();
    }
}