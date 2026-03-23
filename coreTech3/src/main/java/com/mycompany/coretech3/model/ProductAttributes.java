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
import javax.persistence.JoinColumn;
import javax.persistence.ManyToOne;
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
@Table(name = "product_attributes")
@XmlRootElement
@NamedQueries({
    @NamedQuery(name = "ProductAttributes.findAll", query = "SELECT p FROM ProductAttributes p"),
    @NamedQuery(name = "ProductAttributes.findById", query = "SELECT p FROM ProductAttributes p WHERE p.id = :id"),
    @NamedQuery(name = "ProductAttributes.findByValue", query = "SELECT p FROM ProductAttributes p WHERE p.value = :value"),
    @NamedQuery(name = "ProductAttributes.findByCreatedAt", query = "SELECT p FROM ProductAttributes p WHERE p.createdAt = :createdAt"),
    @NamedQuery(name = "ProductAttributes.findByIsDeleted", query = "SELECT p FROM ProductAttributes p WHERE p.isDeleted = :isDeleted"),
    @NamedQuery(name = "ProductAttributes.findByDeletedAt", query = "SELECT p FROM ProductAttributes p WHERE p.deletedAt = :deletedAt")})
public class ProductAttributes implements Serializable {

    private static final long serialVersionUID = 1L;
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Basic(optional = false)
    @Column(name = "id")
    private Integer id;
    @Basic(optional = false)
    @NotNull
    @Size(min = 1, max = 255)
    @Column(name = "value")
    private String value;
    @Basic(optional = false)
    @NotNull
    @Column(name = "created_at")
    @Temporal(TemporalType.TIMESTAMP)
    private Date createdAt;
    @Column(name = "is_deleted")
    private Short isDeleted;
    @Column(name = "deleted_at")
    @Temporal(TemporalType.TIMESTAMP)
    private Date deletedAt;
    @JoinColumn(name = "product_id", referencedColumnName = "id")
    @ManyToOne(optional = false)
    private Products productId;
    @JoinColumn(name = "attribute_id", referencedColumnName = "id")
    @ManyToOne(optional = false)
    private Attributes attributeId;

    public ProductAttributes() {
    }

    public ProductAttributes(Integer id) {
        this.id = id;
    }

    public ProductAttributes(Integer id, String value, Date createdAt) {
        this.id = id;
        this.value = value;
        this.createdAt = createdAt;
    }

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getValue() {
        return value;
    }

    public void setValue(String value) {
        this.value = value;
    }

    public Date getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Date createdAt) {
        this.createdAt = createdAt;
    }

    public Short getIsDeleted() {
        return isDeleted;
    }

    public void setIsDeleted(Short isDeleted) {
        this.isDeleted = isDeleted;
    }

    public Date getDeletedAt() {
        return deletedAt;
    }

    public void setDeletedAt(Date deletedAt) {
        this.deletedAt = deletedAt;
    }

    public Products getProductId() {
        return productId;
    }

    public void setProductId(Products productId) {
        this.productId = productId;
    }

    public Attributes getAttributeId() {
        return attributeId;
    }

    public void setAttributeId(Attributes attributeId) {
        this.attributeId = attributeId;
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
        if (!(object instanceof ProductAttributes)) {
            return false;
        }
        ProductAttributes other = (ProductAttributes) object;
        if ((this.id == null && other.id != null) || (this.id != null && !this.id.equals(other.id))) {
            return false;
        }
        return true;
    }

    @Override
    public String toString() {
        return "com.mycompany.coretech3.model.ProductAttributes[ id=" + id + " ]";
    }
    
}
