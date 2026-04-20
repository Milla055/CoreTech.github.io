import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export interface Product {
  id: number;
  name: string;
  description?: string;
  properties?: any; // JSON properties from database
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

  // Pre-built PC ID-k - ezek csak a kérdőíven keresztül érhetők el
  private readonly PREBUILT_PC_IDS = Array.from({ length: 25 }, (_, i) => 250 + i); // 250-274

  headers = {
    headers: new HttpHeaders({
      'Content-Type': 'application/json',
    })
  };

  // Get auth headers with JWT token for admin operations
  private getAuthHeaders() {
    const token = localStorage.getItem('JWT');
    return {
      headers: new HttpHeaders({
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      })
    };
  }

  // Filter out pre-built PCs from product list
  private filterOutPrebuiltPCs(products: Product[]): Product[] {
    return products.filter(p => !this.PREBUILT_PC_IDS.includes(p.id));
  }

  // Get all products (excluding pre-built PCs)
  getAllProducts(): Observable<Product[]> {
    return this.http.get<ProductsResponse>(`${this.apiUrl}`, this.headers).pipe(
      map(response => {
        console.log('Backend response:', response);
        if (response.status === 'Success' && response.products) {
          const allProducts = response.products.map(p => this.mapBackendProduct(p));
          return this.filterOutPrebuiltPCs(allProducts);
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

  // Get products by category (excluding pre-built PCs)
  getProductsByCategoryId(categoryId: number): Observable<Product[]> {
    return this.http.get<ProductsResponse>(`${this.apiUrl}/category/${categoryId}`, this.headers).pipe(
      map(response => {
        console.log('Backend response for category:', response);
        if (response.status === 'Success' && response.products) {
          const allProducts = response.products.map(p => this.mapBackendProduct(p));
          return this.filterOutPrebuiltPCs(allProducts);
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
      properties: backendProduct.properties, // PROPERTIES ADDED!
      price: backendProduct.price,
      pPrice: backendProduct.p_price || backendProduct.pPrice || backendProduct.price, // Try all variants
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
    const payload = this.mapToBackendProduct(productData);
    return this.http.post<any>(adminUrl, payload, this.getAuthHeaders());
  }

  // Update existing product (admin only)
  updateProduct(productId: number, productData: any): Observable<any> {
    const adminUrl = this.apiUrl.replace('/products', '/admin/products');
    const payload = this.mapToBackendProduct(productData);
    return this.http.put<any>(`${adminUrl}/${productId}`, payload, this.getAuthHeaders());
  }

  // Map frontend product structure to backend expected format
  private mapToBackendProduct(productData: any): any {
    return {
      categoryId: productData.categoryId,
      brandId: productData.brandId,
      name: productData.name,
      description: productData.description || '',
      price: productData.price,
      stock: productData.stock ?? 0,
      imageUrl: productData.imageUrl || '',
      p_price: productData.pPrice ?? productData.p_price ?? 0
    };
  }

  // Delete product (admin only)
  deleteProduct(productId: number): Observable<any> {
    const adminUrl = this.apiUrl.replace('/products', '/admin/products');
    return this.http.put<any>(`${adminUrl}/delete/${productId}`, {}, this.getAuthHeaders());
  }
}