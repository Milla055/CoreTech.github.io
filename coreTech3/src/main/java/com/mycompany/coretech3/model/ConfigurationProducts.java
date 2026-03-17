/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.mycompany.coretech3.model;

import java.io.Serializable;
import java.util.Date;
import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.Table;
import javax.persistence.Temporal;
import javax.persistence.TemporalType;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;
import javax.xml.bind.annotation.XmlRootElement;

/**
 *
 * @author kamil
 */
@Entity
@Table(name = "configuration_products")
@XmlRootElement
@NamedQueries({
    @NamedQuery(name = "ConfigurationProducts.findAll", query = "SELECT c FROM ConfigurationProducts c"),
    @NamedQuery(name = "ConfigurationProducts.findById", query = "SELECT c FROM ConfigurationProducts c WHERE c.id = :id"),
    @NamedQuery(name = "ConfigurationProducts.findByConfigurationId", query = "SELECT c FROM ConfigurationProducts c WHERE c.configurationId = :configurationId"),
    @NamedQuery(name = "ConfigurationProducts.findByProductId", query = "SELECT c FROM ConfigurationProducts c WHERE c.productId = :productId"),
    @NamedQuery(name = "ConfigurationProducts.findByQuantity", query = "SELECT c FROM ConfigurationProducts c WHERE c.quantity = :quantity"),
    @NamedQuery(name = "ConfigurationProducts.findByComponentType", query = "SELECT c FROM ConfigurationProducts c WHERE c.componentType = :componentType"),
    @NamedQuery(name = "ConfigurationProducts.findByIsRequired", query = "SELECT c FROM ConfigurationProducts c WHERE c.isRequired = :isRequired"),
    @NamedQuery(name = "ConfigurationProducts.findByCreatedAt", query = "SELECT c FROM ConfigurationProducts c WHERE c.createdAt = :createdAt"),
    @NamedQuery(name = "ConfigurationProducts.findByIsDeleted", query = "SELECT c FROM ConfigurationProducts c WHERE c.isDeleted = :isDeleted"),
    @NamedQuery(name = "ConfigurationProducts.findByDeletedAt", query = "SELECT c FROM ConfigurationProducts c WHERE c.deletedAt = :deletedAt")})
public class ConfigurationProducts implements Serializable {

    private static final long serialVersionUID = 1L;
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Basic(optional = false)
    @Column(name = "id")
    private Long id;
    @Basic(optional = false)
    @NotNull
    @Column(name = "configuration_id")
    private long configurationId;
    @Basic(optional = false)
    @NotNull
    @Column(name = "product_id")
    private long productId;
    @Basic(optional = false)
    @NotNull
    @Column(name = "quantity")
    private int quantity;
    @Basic(optional = false)
    @NotNull
    @Size(min = 1, max = 11)
    @Column(name = "component_type")
    private String componentType;
    @Column(name = "is_required")
    private Boolean isRequired;
    @Basic(optional = false)
    @NotNull
    @Column(name = "created_at")
    @Temporal(TemporalType.TIMESTAMP)
    private Date createdAt;
    @Column(name = "is_deleted")
    private Boolean isDeleted;
    @Column(name = "deleted_at")
    @Temporal(TemporalType.TIMESTAMP)
    private Date deletedAt;

    public ConfigurationProducts() {
    }

    public ConfigurationProducts(Long id) {
        this.id = id;
    }

    public ConfigurationProducts(Long id, long configurationId, long productId, int quantity, String componentType, Date createdAt) {
        this.id = id;
        this.configurationId = configurationId;
        this.productId = productId;
        this.quantity = quantity;
        this.componentType = componentType;
        this.createdAt = createdAt;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public long getConfigurationId() {
        return configurationId;
    }

    public void setConfigurationId(long configurationId) {
        this.configurationId = configurationId;
    }

    public long getProductId() {
        return productId;
    }

    public void setProductId(long productId) {
        this.productId = productId;
    }

    public int getQuantity() {
        return quantity;
    }

    public void setQuantity(int quantity) {
        this.quantity = quantity;
    }

    public String getComponentType() {
        return componentType;
    }

    public void setComponentType(String componentType) {
        this.componentType = componentType;
    }

    public Boolean getIsRequired() {
        return isRequired;
    }

    public void setIsRequired(Boolean isRequired) {
        this.isRequired = isRequired;
    }

    public Date getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Date createdAt) {
        this.createdAt = createdAt;
    }

    public Boolean getIsDeleted() {
        return isDeleted;
    }

    public void setIsDeleted(Boolean isDeleted) {
        this.isDeleted = isDeleted;
    }

    public Date getDeletedAt() {
        return deletedAt;
    }

    public void setDeletedAt(Date deletedAt) {
        this.deletedAt = deletedAt;
    }

    @Override
    public int hashCode() {
        int hash = 0;
        hash += (id != null ? id.hashCode() : 0);
        return hash;
    }

    @Override
    public boolean equals(Object object) {
        // TODO: Warning - this method won't work in the case the id fields are not set
        if (!(object instanceof ConfigurationProducts)) {
            return false;
        }
        ConfigurationProducts other = (ConfigurationProducts) object;
        if ((this.id == null && other.id != null) || (this.id != null && !this.id.equals(other.id))) {
            return false;
        }
        return true;
    }

    @Override
    public String toString() {
        return "com.mycompany.coretech3.model.ConfigurationProducts[ id=" + id + " ]";
    }
    
}
