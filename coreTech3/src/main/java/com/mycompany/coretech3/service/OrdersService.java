package com.mycompany.coretech3.service;

import com.mycompany.coretech3.model.Orders;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.ParameterMode;
import javax.persistence.StoredProcedureQuery;
import java.util.List;
import org.json.JSONArray;
import org.json.JSONObject;

@Stateless
public class OrdersService {

    @PersistenceContext(unitName = "com.mycompany_coreTech3_war_1.0-SNAPSHOTPU")
    private EntityManager em;

    // customer
    public JSONObject createOrder(int userId, JSONObject orderData) {
        JSONObject resp = new JSONObject();
        try {
            int addressId = orderData.getInt("addressId");
            double totalPrice = orderData.getDouble("totalPrice");
            String status = orderData.optString("status", "pending");
            JSONArray items = orderData.getJSONArray("items");

            // Step 1: Create the order
            StoredProcedureQuery spqOrder = em.createStoredProcedureQuery("createOrders");
            spqOrder.registerStoredProcedureParameter(1, Integer.class, ParameterMode.IN);
            spqOrder.registerStoredProcedureParameter(2, Integer.class, ParameterMode.IN);
            spqOrder.registerStoredProcedureParameter(3, Double.class, ParameterMode.IN);
            spqOrder.registerStoredProcedureParameter(4, String.class, ParameterMode.IN);

            spqOrder.setParameter(1, userId);
            spqOrder.setParameter(2, addressId);
            spqOrder.setParameter(3, totalPrice);
            spqOrder.setParameter(4, status);
            spqOrder.execute();

            // Get the last inserted order ID
            int orderId = ((Number) em.createNativeQuery("SELECT LAST_INSERT_ID()").getSingleResult()).intValue();

            // Step 2: Create order items
            for (int i = 0; i < items.length(); i++) {
                JSONObject item = items.getJSONObject(i);

                StoredProcedureQuery spqItem = em.createStoredProcedureQuery("createOrderItems");
                spqItem.registerStoredProcedureParameter(1, Integer.class, ParameterMode.IN);
                spqItem.registerStoredProcedureParameter(2, Integer.class, ParameterMode.IN);
                spqItem.registerStoredProcedureParameter(3, Integer.class, ParameterMode.IN);
                spqItem.registerStoredProcedureParameter(4, Double.class, ParameterMode.IN);

                spqItem.setParameter(1, orderId);
                spqItem.setParameter(2, item.getInt("productId"));
                spqItem.setParameter(3, item.getInt("quantity"));
                spqItem.setParameter(4, item.getDouble("price"));
                spqItem.execute();
            }

            resp.put("status", "OrderCreated");
            resp.put("statusCode", 201);
            resp.put("orderId", orderId);

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }
        return resp;
    }

    // customer
    public JSONObject getOrdersByUserId(int userId) {
        JSONObject resp = new JSONObject();
        try {
            StoredProcedureQuery spq = em.createStoredProcedureQuery("getOrdersByUserId");
            spq.registerStoredProcedureParameter("userIdIN", Integer.class, ParameterMode.IN);
            spq.setParameter("userIdIN", userId);

            List<Object[]> results = spq.getResultList();

            JSONArray ordersArray = new JSONArray();
            for (Object[] row : results) {
                JSONObject order = new JSONObject();
                order.put("order_id", row[0]);
                order.put("product_name", row[1]);
                order.put("image_url", row[2]);
                order.put("total_price", row[3]);
                order.put("status", row[4]);
                order.put("quantity", row[5]);
                order.put("created_at", row[6]);
                ordersArray.put(order);
            }

            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("orders", ordersArray);
            resp.put("count", ordersArray.length());

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }
        return resp;
    }

    // customer
    public JSONObject getOrderById(int orderId, int userId) {
        JSONObject resp = new JSONObject();
        try {
            // Load order and verify ownership
            Orders order = em.find(Orders.class, orderId);

            if (order == null) {
                resp.put("status", "OrderNotFound");
                resp.put("statusCode", 404);
                resp.put("message", "Order with ID " + orderId + " not found");
                return resp;
            }

            // OWNERSHIP CHECK
            if (order.getUserId().getId() != userId) {
                resp.put("status", "Forbidden");
                resp.put("statusCode", 403);
                resp.put("message", "You don't have permission to view this order");
                return resp;
            }

            // Call stored procedure to get order details
            StoredProcedureQuery spq = em.createStoredProcedureQuery("getOrderById");
            spq.registerStoredProcedureParameter("orderIdIN", Integer.class, ParameterMode.IN);
            spq.setParameter("orderIdIN", orderId);

            List<Object[]> results = spq.getResultList();

            if (results.isEmpty()) {
                resp.put("status", "OrderNotFound");
                resp.put("statusCode", 404);
                return resp;
            }

            // Only 6 columns!
            Object[] row = results.get(0);
            JSONObject orderDetails = new JSONObject();
            orderDetails.put("order_id", row[0]);
            orderDetails.put("user_id", row[1]);
            orderDetails.put("address_id", row[2]);
            orderDetails.put("total_price", row[3]);
            orderDetails.put("status", row[4]);
            orderDetails.put("created_at", row[5]);

            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("order", orderDetails);

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }
        return resp;
    }

    // customer
    public JSONObject deleteMyOrder(int orderId, int userId) {
        JSONObject resp = new JSONObject();
        try {
            Orders order = em.find(Orders.class, orderId);

            if (order == null) {
                resp.put("status", "OrderNotFound");
                resp.put("statusCode", 404);
                return resp;
            }

            // OWNERSHIP CHECK
            if (order.getUserId().getId() != userId) {
                resp.put("status", "Forbidden");
                resp.put("statusCode", 403);
                resp.put("message", "You don't have permission to delete this order");
                return resp;
            }

            // CHECK IF PENDING
            if (!"pending".equalsIgnoreCase(order.getStatus())) {
                resp.put("status", "CannotDelete");
                resp.put("statusCode", 400);
                resp.put("message", "Can only cancel orders with 'pending' status");
                return resp;
            }

            // Check if already deleted
            if (order.getIsDeleted() != null && order.getIsDeleted() != 0) {
                resp.put("status", "AlreadyDeleted");
                resp.put("statusCode", 400);
                return resp;
            }

            StoredProcedureQuery spq = em.createStoredProcedureQuery("softDelOrders");
            spq.registerStoredProcedureParameter("ordersIdIN", Integer.class, ParameterMode.IN);
            spq.setParameter("ordersIdIN", orderId);
            spq.execute();

            resp.put("status", "OrderCancelled");
            resp.put("statusCode", 200);

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }
        return resp;
    }

    public JSONObject getAllOrders() {
        JSONObject resp = new JSONObject();
        try {
            StoredProcedureQuery spq = em.createStoredProcedureQuery("getAllOrders");
            List<Object[]> results = spq.getResultList();

            JSONArray ordersArray = new JSONArray();
            for (Object[] row : results) {
                JSONObject order = new JSONObject();
                order.put("order_id", row[0]);
                order.put("user_id", row[1]);
                order.put("address_id", row[2]);
                order.put("total_price", row[3]);
                order.put("status", row[4]);
                order.put("created_at", row[5]);
                order.put("username", row[6]);
                ordersArray.put(order);
            }

            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("orders", ordersArray);
            resp.put("count", ordersArray.length());

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }
        return resp;
    }

    public JSONObject updateOrderStatus(int orderId, String newStatus) {
        JSONObject resp = new JSONObject();
        try {
            // Validate status
            String[] validStatuses = {"pending", "processing", "shipping", "delivered", "cancelled"};
            boolean isValid = false;
            for (String status : validStatuses) {
                if (status.equalsIgnoreCase(newStatus)) {
                    isValid = true;
                    break;
                }
            }

            if (!isValid) {
                resp.put("status", "InvalidStatus");
                resp.put("statusCode", 400);
                resp.put("message", "Status must be: pending, processing, shipping, delivered, or cancelled");
                return resp;
            }

            // Check if order exists
            Orders order = em.find(Orders.class, orderId);
            if (order == null) {
                resp.put("status", "OrderNotFound");
                resp.put("statusCode", 404);
                return resp;
            }

            // Update status using stored procedure
            StoredProcedureQuery spq = em.createStoredProcedureQuery("updateOrderById");
            spq.registerStoredProcedureParameter("orderIdIN", Integer.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("statusIN", String.class, ParameterMode.IN);

            spq.setParameter("orderIdIN", orderId);
            spq.setParameter("statusIN", newStatus);
            spq.execute();

            resp.put("status", "OrderUpdated");
            resp.put("statusCode", 200);
            resp.put("message", "Order status updated to: " + newStatus);

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }
        return resp;
    }

    public JSONObject deleteOrderAdmin(int orderId) {
        JSONObject resp = new JSONObject();
        try {
            Orders order = em.find(Orders.class, orderId);

            if (order == null) {
                resp.put("status", "OrderNotFound");
                resp.put("statusCode", 404);
                return resp;
            }

            // Check if already deleted
            if (order.getIsDeleted() != null && order.getIsDeleted() != 0) {
                resp.put("status", "AlreadyDeleted");
                resp.put("statusCode", 400);
                resp.put("message", "Order is already deleted");
                return resp;
            }

            // Admin can delete any order (no status check)
            StoredProcedureQuery spq = em.createStoredProcedureQuery("softDelOrders");
            spq.registerStoredProcedureParameter("ordersIdIN", Integer.class, ParameterMode.IN);
            spq.setParameter("ordersIdIN", orderId);
            spq.execute();

            resp.put("status", "OrderDeleted");
            resp.put("statusCode", 200);
            resp.put("message", "Order deleted successfully");

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }
        return resp;
    }

    public JSONObject checkout(int userId, int addressId) {
        JSONObject resp = new JSONObject();
        try {
            StoredProcedureQuery spq = em.createStoredProcedureQuery("checkout");
            spq.registerStoredProcedureParameter("userIdIN", Integer.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("addressIdIN", Integer.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("newOrderId", Integer.class, ParameterMode.OUT);

            spq.setParameter("userIdIN", userId);
            spq.setParameter("addressIdIN", addressId);
            spq.execute();

            // Get the new order ID
            Integer orderId = (Integer) spq.getOutputParameterValue("newOrderId");

            resp.put("status", "OrderCreated");
            resp.put("statusCode", 201);
            resp.put("message", "Order created successfully");
            resp.put("orderId", orderId);

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }
        return resp;
    }
}
