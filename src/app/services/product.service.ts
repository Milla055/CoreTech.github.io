import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export interface Product {
  id: number;
  name: string;
  description?: string;
  price: number;
  pPrice: number; // p_price from database (promotional/discounted price)
  stock?: number;
  imageUrl: string;
  categoryId?: {
    id: number;
    name: string;
  };
  brandId?: {
    id: number;
    name: string;
  };
  createdAt?: string;
  isDeleted?: number;
}

// Backend response interfaces
interface ProductResponse {
  status: string;
  statusCode: number;
  product: any;
}

interface ProductsResponse {
  status: string;
  statusCode: number;
  products: any[];
  count: number;
  categoryId?: number;
}

@Injectable({
  providedIn: 'root'
})
export class ProductService {
  private apiUrl = 'http://127.0.0.1:8080/coreTech3-1.0-SNAPSHOT/webresources/products';
  private http = inject(HttpClient);

  headers = {
    headers: new HttpHeaders({
      'Content-Type': 'application/json',
    })
  };

  // Get all products
  getAllProducts(): Observable<Product[]> {
    return this.http.get<ProductsResponse>(`${this.apiUrl}`, this.headers).pipe(
      map(response => {
        console.log('Backend response:', response);
        if (response.status === 'Success' && response.products) {
          return response.products.map(p => this.mapBackendProduct(p));
        }
        return [];
      })
    );
  }

  // Get single product by ID
  getProductById(id: number): Observable<Product> {
    return this.http.get<ProductResponse>(`${this.apiUrl}/${id}`, this.headers).pipe(
      map(response => {
        console.log('Backend response for product:', response);
        if (response.status === 'Success' && response.product) {
          return this.mapBackendProduct(response.product);
        }
        throw new Error('Product not found');
      })
    );
  }

  // Get products by category
  getProductsByCategoryId(categoryId: number): Observable<Product[]> {
    return this.http.get<ProductsResponse>(`${this.apiUrl}/category/${categoryId}`, this.headers).pipe(
      map(response => {
        console.log('Backend response for category:', response);
        if (response.status === 'Success' && response.products) {
          return response.products.map(p => this.mapBackendProduct(p));
        }
        return [];
      })
    );
  }

  // Map backend product structure to frontend Product interface
  private mapBackendProduct(backendProduct: any): Product {
    // Use placeholder image if image_url is null or empty
    const placeholderImage = 'assets/placeholder-product.png';
    
    return {
      id: backendProduct.id,
      name: backendProduct.name,
      description: backendProduct.description,
      price: backendProduct.price,
      pPrice: backendProduct.price, // Use same as price if no p_price in backend
      stock: backendProduct.stock,
      imageUrl: backendProduct.image_url || placeholderImage,
      categoryId: {
        id: backendProduct.category_id,
        name: backendProduct.category_name || ''
      },
      brandId: {
        id: backendProduct.brand_id,
        name: backendProduct.brand_name || ''
      },
      createdAt: backendProduct.created_at
    };
  }

  // Add product to cart (optional - keep your existing implementation)
  addToCart(productId: number, quantity: number): Observable<any> {
    const token = localStorage.getItem('JWT');
    const headers = new HttpHeaders({
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    });

    const body = {
      productId: productId,
      quantity: quantity
    };

    return this.http.post(`${this.apiUrl.replace('/products', '/Cart/add')}`, body, { headers });
  }

  // ==================== ADMIN PRODUCT MANAGEMENT ====================
  
  // Create new product (admin only)
  createProduct(productData: any): Observable<any> {
    const adminUrl = this.apiUrl.replace('/products', '/admin/products');
    return this.http.post<any>(adminUrl, productData, this.headers);
  }

  // Update existing product (admin only)
  updateProduct(productId: number, productData: any): Observable<any> {
    const adminUrl = this.apiUrl.replace('/products', '/admin/products');
    return this.http.put<any>(`${adminUrl}/${productId}`, productData, this.headers);
  }

  // Delete product (admin only)
  deleteProduct(productId: number): Observable<any> {
    const adminUrl = this.apiUrl.replace('/products', '/admin/products');
    return this.http.put<any>(`${adminUrl}/delete/${productId}`, {}, this.headers);
  }
}