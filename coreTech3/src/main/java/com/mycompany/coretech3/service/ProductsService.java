package com.mycompany.coretech3.service;

import com.mycompany.coretech3.model.Products;
import java.util.List;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.ParameterMode;
import javax.persistence.PersistenceContext;
import javax.persistence.StoredProcedureQuery;
import org.json.JSONArray;
import org.json.JSONObject;

@Stateless
public class ProductsService {

    @PersistenceContext(unitName = "com.mycompany_coreTech3_war_1.0-SNAPSHOTPU")
    private EntityManager em;

    public JSONObject getAllProducts() {
        JSONObject resp = new JSONObject();
        try {
            StoredProcedureQuery spq = em.createStoredProcedureQuery("getAllProducts");
            List<Object[]> results = spq.getResultList();

            JSONArray productsArray = new JSONArray();
            for (Object[] row : results) {
                JSONObject product = new JSONObject();
                product.put("id", row[0]);
                product.put("name", row[1]);
                product.put("description", row[2]);
                product.put("price", row[3]);
                product.put("stock", row[4]);
                product.put("image_url", row[5]);
                product.put("category_id", row[6]);
                product.put("brand_id", row[7]);
                product.put("created_at", row[8]);
                product.put("category_name", row[9]);
                product.put("brand_name", row[10]);
                productsArray.put(product);
            }

            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("products", productsArray);
            resp.put("count", productsArray.length());

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }
        return resp;
    }

    public JSONObject getProductById(int productId) {
        JSONObject resp = new JSONObject();
        try {
            StoredProcedureQuery spq = em.createStoredProcedureQuery("getProductById");
            spq.registerStoredProcedureParameter("productIdIN", Integer.class, ParameterMode.IN);
            spq.setParameter("productIdIN", productId);

            List<Object[]> results = spq.getResultList();

            if (results == null || results.isEmpty()) {
                resp.put("status", "ProductNotFound");
                resp.put("statusCode", 404);
                resp.put("message", "Product with ID " + productId + " not found");
                return resp;
            }

            Object[] row = results.get(0);
            JSONObject product = new JSONObject();
            product.put("id", row[0]);
            product.put("name", row[1]);
            product.put("description", row[2]);
            product.put("price", row[3]);
            product.put("stock", row[4]);
            product.put("image_url", row[5]);
            product.put("category_id", row[6]);
            product.put("brand_id", row[7]);
            product.put("created_at", row[8]);
            product.put("category_name", row[9]);
            product.put("brand_name", row[10]);

            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("product", product);

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }
        return resp;
    }

    public JSONObject getProductsByBrandId(int brandId) {
        JSONObject resp = new JSONObject();
        try {
            StoredProcedureQuery spq = em.createStoredProcedureQuery("getProductsByBrandId");
            spq.registerStoredProcedureParameter("brandIdIN", Integer.class, ParameterMode.IN);
            spq.setParameter("brandIdIN", brandId);

            List<Object[]> results = spq.getResultList();

            JSONArray productsArray = new JSONArray();
            for (Object[] row : results) {
                JSONObject product = new JSONObject();
                product.put("id", row[0]);
                product.put("name", row[1]);
                product.put("description", row[2]);
                product.put("price", row[3]);
                product.put("stock", row[4]);
                product.put("image_url", row[5]);
                product.put("category_id", row[6]);
                product.put("brand_id", row[7]);
                product.put("created_at", row[8]);
                product.put("brand_name", row[9]);
                productsArray.put(product);
            }

            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("products", productsArray);
            resp.put("count", productsArray.length());
            resp.put("brandId", brandId);

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }
        return resp;
    }

    public JSONObject createProduct(int categoryId, int brandId, String name,
            String description, double price, int stock, String imageUrl) {
        JSONObject resp = new JSONObject();
        try {
            StoredProcedureQuery spq = em.createStoredProcedureQuery("createProducts");

            // Register parameters in DATABASE PROCEDURE ORDER
            spq.registerStoredProcedureParameter(1, Integer.class, ParameterMode.IN); // categoryIdIN
            spq.registerStoredProcedureParameter(2, Integer.class, ParameterMode.IN); // brandIdIN
            spq.registerStoredProcedureParameter(3, String.class, ParameterMode.IN);  // nameIN
            spq.registerStoredProcedureParameter(4, String.class, ParameterMode.IN);  // descriptionIN
            spq.registerStoredProcedureParameter(5, Double.class, ParameterMode.IN);  // priceIN
            spq.registerStoredProcedureParameter(6, Integer.class, ParameterMode.IN); // stockIN
            spq.registerStoredProcedureParameter(7, String.class, ParameterMode.IN);  // imageurlIN

            // Set parameters BY POSITION
            spq.setParameter(1, categoryId);
            spq.setParameter(2, brandId);
            spq.setParameter(3, name);
            spq.setParameter(4, description);
            spq.setParameter(5, price);
            spq.setParameter(6, stock);
            spq.setParameter(7, imageUrl);

            spq.execute();

            resp.put("status", "ProductCreated");
            resp.put("statusCode", 201);
            resp.put("message", "Product created successfully");

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }
        return resp;
    }

    public JSONObject updateProduct(int productId, int categoryId, int brandId,
            String name, String description, double price,
            int stock, String imageUrl) {
        JSONObject resp = new JSONObject();
        try {
            // Check if product exists
            Products product = em.find(Products.class, productId);
            if (product == null) {
                resp.put("status", "ProductNotFound");
                resp.put("statusCode", 404);
                resp.put("message", "Product with ID " + productId + " not found");
                return resp;
            }

            StoredProcedureQuery spq = em.createStoredProcedureQuery("updateProductById");
            spq.registerStoredProcedureParameter("productIdIN", Integer.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("nameIN", String.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("descriptionIN", String.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("priceIN", Double.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("stockIN", Integer.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("imageurlIN", String.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("categoryIdIN", Integer.class, ParameterMode.IN);
            spq.registerStoredProcedureParameter("brandIdIN", Integer.class, ParameterMode.IN);

            spq.setParameter("productIdIN", productId);
            spq.setParameter("nameIN", name);
            spq.setParameter("descriptionIN", description);
            spq.setParameter("priceIN", price);
            spq.setParameter("stockIN", stock);
            spq.setParameter("imageurlIN", imageUrl);
            spq.setParameter("categoryIdIN", categoryId);
            spq.setParameter("brandIdIN", brandId);

            spq.execute();

            resp.put("status", "ProductUpdated");
            resp.put("statusCode", 200);
            resp.put("message", "Product updated successfully");

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }
        return resp;
    }

    public JSONObject deleteProduct(int productId) {
        JSONObject resp = new JSONObject();
        try {
            Products product = em.find(Products.class, productId);
            if (product == null) {
                resp.put("status", "ProductNotFound");
                resp.put("statusCode", 404);
                resp.put("message", "Product with ID " + productId + " not found");
                return resp;
            }

            if (product.getIsDeleted() != null && product.getIsDeleted() != 0) {
                resp.put("status", "AlreadyDeleted");
                resp.put("statusCode", 400);
                resp.put("message", "Product is already deleted");
                return resp;
            }

            StoredProcedureQuery spq = em.createStoredProcedureQuery("softDelProducts");
            spq.registerStoredProcedureParameter("productsIdIN", Integer.class, ParameterMode.IN);
            spq.setParameter("productsIdIN", productId);
            spq.execute();

            resp.put("status", "ProductDeleted");
            resp.put("statusCode", 200);
            resp.put("message", "Product deleted successfully");

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }
        return resp;
    }

    public JSONObject getProductsByCategoryId(int categoryId) {
        JSONObject resp = new JSONObject();
        try {
            StoredProcedureQuery spq = em.createStoredProcedureQuery("getProductsByCategoryId");
            spq.registerStoredProcedureParameter("categoryIdIN", Integer.class, ParameterMode.IN);
            spq.setParameter("categoryIdIN", categoryId);

            List<Object[]> results = spq.getResultList();

            JSONArray productsArray = new JSONArray();
            for (Object[] row : results) {
                JSONObject product = new JSONObject();
                product.put("id", row[0]);
                product.put("name", row[1]);
                product.put("description", row[2]);
                product.put("price", row[3]);
                product.put("stock", row[4]);
                product.put("image_url", row[5]);
                product.put("category_id", row[6]);
                product.put("brand_id", row[7]);
                product.put("created_at", row[8]);
                product.put("brand_name", row[9]);
                productsArray.put(product);
            }

            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("products", productsArray);
            resp.put("count", productsArray.length());
            resp.put("categoryId", categoryId);

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }
        return resp;
    }

}
