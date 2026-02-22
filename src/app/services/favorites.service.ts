import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { map, tap, catchError } from 'rxjs/operators';

export interface FavoriteProduct {
  id: number;
  name: string;
  description: string;
  price: number;
  pPrice: number;
  stock: number;
  imageUrl: string;
  categoryId: number;
  categoryName: string;
  brandId: number;
  brandName: string;
  addedAt: string;
}

@Injectable({
  providedIn: 'root'
})
export class FavoritesService {
  private apiUrl = 'http://127.0.0.1:8080/coreTech3-1.0-SNAPSHOT/webresources';
  
  private favoritesSubject = new BehaviorSubject<FavoriteProduct[]>([]);
  public favorites$ = this.favoritesSubject.asObservable();

  constructor(private http: HttpClient) {
    console.log('🚀 FavoritesService initialized');
    this.loadFavoritesFromBackend();
  }

  private getAuthHeaders(): HttpHeaders {
    const token = localStorage.getItem('JWT');
    return new HttpHeaders({
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    });
  }

  // Load favorites from backend
  loadFavoritesFromBackend(): void {
    const token = localStorage.getItem('JWT');
    console.log('🔍 Loading favorites... JWT:', token ? 'EXISTS' : 'MISSING');
    
    if (!token) {
      console.log('⚠️ No JWT token - skipping favorites load');
      this.favoritesSubject.next([]);
      return;
    }

    console.log('📡 Calling backend: GET /favorites');
    
    this.http.get<any>(`${this.apiUrl}/favorites`, {
      headers: this.getAuthHeaders()
    }).pipe(
      map(response => {
        console.log('📥 Backend response:', response);
        
        if (response.status === 'Success' && response.favorites) {
          console.log('✅ Found favorites:', response.favorites.length);
          return response.favorites.map((fav: any) => ({
            id: fav.product_id,
            name: fav.product_name || '',
            description: '',
            price: fav.product_price || 0,
            pPrice: fav.product_price || 0,
            stock: 0,
            imageUrl: '',
            categoryId: 0,
            categoryName: fav.category_name || '',
            brandId: 0,
            brandName: fav.brand_name || '',
            addedAt: fav.created_at || new Date().toISOString()
          }));
        }
        console.log('⚠️ No favorites in response or wrong format');
        return [];
      }),
      catchError(err => {
        console.error('❌ Error loading favorites:', err);
        console.error('❌ Error details:', err.error);
        console.error('❌ Status:', err.status);
        return of([]);
      })
    ).subscribe(favorites => {
      console.log('💾 Setting favorites in BehaviorSubject:', favorites);
      this.favoritesSubject.next(favorites);
      console.log('📦 Kedvencek betöltve backend-ről:', favorites.length, 'db');
    });
  }

  // Get favorites
  getFavorites(): FavoriteProduct[] {
    return this.favoritesSubject.value;
  }

  getFavorites$(): Observable<FavoriteProduct[]> {
    return this.favorites$;
  }

  // Add to favorites
  addFavorite(product: any): Observable<{ success: boolean; message: string }> {
    const productId = product.id;

    if (this.isFavorite(productId)) {
      return of({ success: false, message: 'A termék már a kedvencek között van!' });
    }

    return this.http.post<any>(`${this.apiUrl}/favorites/${productId}`, {}, {
      headers: this.getAuthHeaders()
    }).pipe(
      tap(response => {
        console.log('✅ Backend response:', response);
        
        // Add to local state immediately
        const newFavorite: FavoriteProduct = {
          id: product.id,
          name: product.name || '',
          description: product.description || '',
          price: product.price || 0,
          pPrice: product.pPrice || product.p_price || 0,
          stock: product.stock || 0,
          imageUrl: product.imageUrl || product.image_url || '',
          categoryId: product.categoryId?.id || product.category_id || 0,
          categoryName: product.categoryId?.name || product.category_name || '',
          brandId: product.brandId?.id || product.brand_id || 0,
          brandName: product.brandId?.name || product.brand_name || '',
          addedAt: new Date().toISOString()
        };

        const currentFavorites = this.favoritesSubject.value;
        this.favoritesSubject.next([...currentFavorites, newFavorite]);
        
        console.log('❤️ Kedvencekhez adva:', newFavorite.name);
      }),
      map(response => ({
        success: response.status === 'FavoriteAdded',
        message: response.message || 'Termék hozzáadva a kedvencekhez!'
      })),
      catchError(err => {
        console.error('❌ Error adding favorite:', err);
        return of({ 
          success: false, 
          message: 'Hiba történt a kedvenc hozzáadása során!' 
        });
      })
    );
  }

  // Remove from favorites
  removeFavorite(productId: number): Observable<{ success: boolean; message: string }> {
    return this.http.put<any>(`${this.apiUrl}/favorites/${productId}`, {}, {
      headers: this.getAuthHeaders()
    }).pipe(
      tap(response => {
        console.log('✅ Backend response:', response);
        
        // Remove from local state immediately
        const currentFavorites = this.favoritesSubject.value;
        const updatedFavorites = currentFavorites.filter(f => f.id !== productId);
        this.favoritesSubject.next(updatedFavorites);
        
        console.log('💔 Kedvencekből törölve:', productId);
      }),
      map(response => ({
        success: response.status === 'FavoriteRemoved',
        message: response.message || 'Termék eltávolítva a kedvencekből!'
      })),
      catchError(err => {
        console.error('❌ Error removing favorite:', err);
        return of({ 
          success: false, 
          message: 'Hiba történt a kedvenc eltávolítása során!' 
        });
      })
    );
  }

  // Toggle favorite
  toggleFavorite(product: any): Observable<{ success: boolean; message: string; isFavorite: boolean }> {
    if (this.isFavorite(product.id)) {
      return this.removeFavorite(product.id).pipe(
        map(result => ({ ...result, isFavorite: false }))
      );
    } else {
      return this.addFavorite(product).pipe(
        map(result => ({ ...result, isFavorite: true }))
      );
    }
  }

  // Check if favorite
  isFavorite(productId: number): boolean {
    return this.favoritesSubject.value.some(f => f.id === productId);
  }

  // Get favorite count
  getFavoriteCount(): number {
    return this.favoritesSubject.value.length;
  }

  // Clear favorites (on logout)
  clearFavorites(): void {
    this.favoritesSubject.next([]);
    console.log('🗑️ Kedvencek törölve (kijelentkezés)');
  }

  // Refresh from backend
  refresh(): void {
    this.loadFavoritesFromBackend();
  }
}