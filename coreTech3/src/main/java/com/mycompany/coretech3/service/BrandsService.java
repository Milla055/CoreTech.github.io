package com.mycompany.coretech3.service;

import com.mycompany.coretech3.model.Brands;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.ParameterMode;
import javax.persistence.StoredProcedureQuery;
import java.util.List;
import org.json.JSONArray;
import org.json.JSONObject;

@Stateless
public class BrandsService {

    @PersistenceContext(unitName = "com.mycompany_coreTech3_war_1.0-SNAPSHOTPU")
    private EntityManager em;

    public JSONObject getAllBrands() {
        JSONObject resp = new JSONObject();
        try {
            StoredProcedureQuery spq = em.createStoredProcedureQuery("getAllBrands");
            List<Object[]> results = spq.getResultList();

            JSONArray brandsArray = new JSONArray();
            for (Object[] row : results) {
                JSONObject brand = new JSONObject();
                brand.put("id", row[0]);
                brand.put("name", row[1]);
                brand.put("description", row[2]);
                brand.put("logo_url", row[3]);
                brand.put("created_at", row[4]);
                brandsArray.put(brand);
            }

            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("brands", brandsArray);
            resp.put("count", brandsArray.length());

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }
        return resp;
    }

    public JSONObject getBrandById(int brandId) {
        JSONObject resp = new JSONObject();
        try {
            StoredProcedureQuery spq = em.createStoredProcedureQuery("getBrandById");
            spq.registerStoredProcedureParameter("brandIdIN", Integer.class, ParameterMode.IN);
            spq.setParameter("brandIdIN", brandId);

            List<Object[]> results = spq.getResultList();

            if (results == null || results.isEmpty()) {
                resp.put("status", "BrandNotFound");
                resp.put("statusCode", 404);
                resp.put("message", "Brand with ID " + brandId + " not found");
                return resp;
            }

            Object[] row = results.get(0);
            JSONObject brand = new JSONObject();
            brand.put("id", row[0]);
            brand.put("name", row[1]);
            brand.put("description", row[2]);
            brand.put("logo_url", row[3]);
            brand.put("created_at", row[4]);

            resp.put("status", "Success");
            resp.put("statusCode", 200);
            resp.put("brand", brand);

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }
        return resp;
    }

    // ========== (ADMIN) ==========
    public JSONObject createBrand(String name, String description, String logoUrl) {
        JSONObject resp = new JSONObject();
        try {
            StoredProcedureQuery spq = em.createStoredProcedureQuery("createBrands");
            spq.registerStoredProcedureParameter(1, String.class, ParameterMode.IN);  // nameIN
            spq.registerStoredProcedureParameter(2, String.class, ParameterMode.IN);  // descriptionIN
            spq.registerStoredProcedureParameter(3, String.class, ParameterMode.IN);  // logourlIN

            spq.setParameter(1, name);
            spq.setParameter(2, description);
            spq.setParameter(3, logoUrl);

            spq.execute();

            resp.put("status", "BrandCreated");
            resp.put("statusCode", 201);
            resp.put("message", "Brand created successfully");

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }
        return resp;
    }

    public JSONObject deleteBrand(int brandId) {
        JSONObject resp = new JSONObject();
        try {
            Brands brand = em.find(Brands.class, brandId);
            if (brand == null) {
                resp.put("status", "BrandNotFound");
                resp.put("statusCode", 404);
                resp.put("message", "Brand with ID " + brandId + " not found");
                return resp;
            }

            // Check if already deleted
            if (brand.getIsDeleted() != null && brand.getIsDeleted() != 0) {
                resp.put("status", "AlreadyDeleted");
                resp.put("statusCode", 400);
                resp.put("message", "Brand is already deleted");
                return resp;
            }

            StoredProcedureQuery spq = em.createStoredProcedureQuery("softDelBrands");
            spq.registerStoredProcedureParameter("brandsIdIN", Integer.class, ParameterMode.IN);
            spq.setParameter("brandsIdIN", brandId);
            spq.execute();

            resp.put("status", "BrandDeleted");
            resp.put("statusCode", 200);
            resp.put("message", "Brand deleted successfully");

        } catch (Exception e) {
            e.printStackTrace();
            resp.put("status", "DatabaseError");
            resp.put("statusCode", 500);
            resp.put("message", e.getMessage());
        }
        return resp;
    }
}
