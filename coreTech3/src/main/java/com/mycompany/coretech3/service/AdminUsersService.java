package com.mycompany.coretech3.service;

import com.mycompany.coretech3.model.Users;
import java.util.List;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.ParameterMode;
import javax.persistence.PersistenceContext;
import javax.persistence.StoredProcedureQuery;
import org.json.JSONArray;
import org.json.JSONObject;

@Stateless
public class AdminUsersService {

    @PersistenceContext(unitName = "com.mycompany_coreTech3_war_1.0-SNAPSHOTPU")
    private EntityManager em;

    public JSONObject getAllUsersAdmin() {
        JSONObject resp = new JSONObject();
        try {
            List<Users> users = em.createQuery(
                    "SELECT u FROM Users u ORDER BY u.id",
                    Users.class
            ).getResultList();

            JSONArray usersArray = new JSONArray();
            for (Users u : users) {
                JSONObject obj = new JSONObject();
                obj.put("id", u.getId());
                obj.put("username", u.getUsername());
                obj.put("email", u.getEmail());
                obj.put("phone", u.getPhone());
                obj.put("role", u.getRole());
                obj.put("created_at", u.getCreatedAt());
                obj.put("is_deleted", u.getIsDeleted());
                obj.put("deleted_at", u.getDeletedAt());
                usersArray.put(obj);
            }

            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("users", usersArray);
            resp.put("count", usersArray.length());

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }

        return resp;
    }

    public JSONObject getUserById(int userId) {
        JSONObject resp = new JSONObject();
        try {
            // Call stored procedure
            StoredProcedureQuery spq = em.createStoredProcedureQuery("getUserById");
            spq.registerStoredProcedureParameter("userIdIN", Integer.class, ParameterMode.IN);
            spq.setParameter("userIdIN", userId);

            List<Object[]> results = spq.getResultList();

            if (results == null || results.isEmpty()) {
                resp.put("status", "UserNotFound");
                resp.put("statusCode", 404);
                resp.put("message", "User with ID " + userId + " not found");
                return resp;
            }

            // Get the first result
            Object[] row = results.get(0);

            JSONObject userObj = new JSONObject();
            userObj.put("id", row[0]);
            userObj.put("username", row[1]);
            userObj.put("email", row[2]);
            userObj.put("role", row[3]);
            userObj.put("created_at", row[4]);

            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("user", userObj);

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }

        return resp;
    }

    public JSONObject getAdmins() {
        JSONObject resp = new JSONObject();
        try {
            List<Object[]> rows = em.createNativeQuery(
                    "SELECT id, username, email, phone, role, created_at "
                    + "FROM users "
                    + "WHERE role = 'admin' AND (is_deleted IS NULL OR is_deleted = 0) "
                    + "ORDER BY created_at DESC"
            ).getResultList();

            JSONArray adminsArray = new JSONArray();
            for (Object[] row : rows) {
                JSONObject obj = new JSONObject();
                obj.put("id", row[0]);
                obj.put("username", row[1]);
                obj.put("email", row[2]);
                obj.put("phone", row[3]);
                obj.put("role", row[4]);
                obj.put("created_at", row[5]);
                adminsArray.put(obj);
            }

            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("admins", adminsArray);
            resp.put("count", adminsArray.length());

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }

        return resp;
    }

    public JSONObject getCustomers() {
        JSONObject resp = new JSONObject();
        try {
            List<Object[]> rows = em.createNativeQuery(
                    "SELECT id, username, email, phone, role, created_at "
                    + "FROM users "
                    + "WHERE role = 'customer' AND (is_deleted IS NULL OR is_deleted = 0) "
                    + "ORDER BY created_at DESC"
            ).getResultList();

            JSONArray customersArray = new JSONArray();
            for (Object[] row : rows) {
                JSONObject obj = new JSONObject();
                obj.put("id", row[0]);
                obj.put("username", row[1]);
                obj.put("email", row[2]);
                obj.put("phone", row[3]);
                obj.put("role", row[4]);
                obj.put("created_at", row[5]);
                customersArray.put(obj);
            }

            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("customers", customersArray);
            resp.put("count", customersArray.length());

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }

        return resp;
    }

    public JSONObject updateUserRole(int userId, String newRole) {
        JSONObject resp = new JSONObject();
        try {
            Users user = em.find(Users.class, userId);

            if (user == null) {
                resp.put("status", "UserNotFound");
                resp.put("statusCode", 404);
                resp.put("message", "User with ID " + userId + " not found");
                return resp;
            }

            // Validate role
            if (!newRole.equals("admin") && !newRole.equals("customer")) {
                resp.put("status", "InvalidRole");
                resp.put("statusCode", 400);
                resp.put("message", "Role must be 'admin' or 'customer'");
                return resp;
            }

            user.setRole(newRole);
            em.merge(user);

            resp.put("status", "RoleUpdated");
            resp.put("statusCode", 200);
            resp.put("message", "User role updated successfully");
            resp.put("userId", userId);
            resp.put("newRole", newRole);

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }

        return resp;
    }

    public JSONObject softDeleteUser(int userId) {
        JSONObject resp = new JSONObject();
        try {
            Users user = em.find(Users.class, userId);

            if (user == null) {
                resp.put("status", "UserNotFound");
                resp.put("statusCode", 404);
                resp.put("message", "User with ID " + userId + " not found");
                return resp;
            }

            if (Boolean.TRUE.equals(user.getIsDeleted())) {
                resp.put("status", "AlreadyDeleted");
                resp.put("statusCode", 400);
                resp.put("message", "User is already deleted");
                return resp;
            }

            // PREVENT DELETING ADMINS
            if ("admin".equalsIgnoreCase(user.getRole())) {
                resp.put("status", "CannotDeleteAdmin");
                resp.put("statusCode", 403);
                resp.put("message", "Cannot delete admin users");
                return resp;
            }

            // Call stored procedure
            StoredProcedureQuery spq = em.createStoredProcedureQuery("softDelUser");
            spq.registerStoredProcedureParameter("userIDIN", Integer.class, ParameterMode.IN);
            spq.setParameter("userIDIN", userId);
            spq.execute();

            resp.put("status", "UserSoftDeleted");
            resp.put("statusCode", 200);
            resp.put("message", "User successfully deleted");
            resp.put("userId", userId);

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }

        return resp;
    }
}
