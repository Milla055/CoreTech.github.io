import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';

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

@Injectable({
  providedIn: 'root'
})
export class ProductService {
  private apiUrl = 'http://127.0.0.1:8080/coreTech3-1.0-SNAPSHOT/webresources';
  private http = inject(HttpClient);

  headers = {
    headers: new HttpHeaders({
      'Content-Type': 'application/json',
    })
  };

  // Get all products (not deleted)
  getAllProducts(): Observable<Product[]> {
    return this.http.get<Product[]>(`${this.apiUrl}/Products/getAll`, this.headers);
  }

  // Get single product by ID
  getProductById(id: number): Observable<Product> {
    return this.http.get<Product>(`${this.apiUrl}/Products/getById/${id}`, this.headers);
  }

  // Get products by category
  getProductsByCategoryId(categoryId: number): Observable<Product[]> {
    return this.http.get<Product[]>(`${this.apiUrl}/Products/getByCategoryId/${categoryId}`, this.headers);
  }

  // Add product to cart (optional)
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

    return this.http.post(`${this.apiUrl}/Cart/add`, body, { headers });
  }
}