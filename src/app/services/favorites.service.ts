import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable, of } from 'rxjs';

// Egyszerűsített Favorite interface - a tárolt adatok
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
  private STORAGE_KEY = 'user_favorites';
  
  // BehaviorSubject a kedvencek listájához
  private favoritesSubject = new BehaviorSubject<FavoriteProduct[]>([]);
  public favorites$ = this.favoritesSubject.asObservable();

  constructor() {
    this.loadFromLocalStorage();
  }

  // LocalStorage-ból betöltés
  private loadFromLocalStorage(): void {
    try {
      const stored = localStorage.getItem(this.STORAGE_KEY);
      if (stored) {
        const favorites = JSON.parse(stored) as FavoriteProduct[];
        this.favoritesSubject.next(favorites);
        console.log('📦 Kedvencek betöltve:', favorites.length, 'db');
      }
    } catch (e) {
      console.error('Hiba a kedvencek betöltésekor:', e);
      this.favoritesSubject.next([]);
    }
  }

  // LocalStorage-ba mentés
  private saveToLocalStorage(): void {
    try {
      const favorites = this.favoritesSubject.value;
      localStorage.setItem(this.STORAGE_KEY, JSON.stringify(favorites));
      console.log('💾 Kedvencek mentve:', favorites.length, 'db');
    } catch (e) {
      console.error('Hiba a kedvencek mentésekor:', e);
    }
  }

  // Kedvencek lekérése
  getFavorites(): FavoriteProduct[] {
    return this.favoritesSubject.value;
  }

  // Kedvencek lekérése Observable-ként
  getFavorites$(): Observable<FavoriteProduct[]> {
    return this.favorites$;
  }

  // Kedvenc hozzáadása (teljes termék adatokkal)
  addFavorite(product: any): Observable<{ success: boolean; message: string }> {
    const currentFavorites = this.favoritesSubject.value;
    
    // Ellenőrzés: már kedvenc-e
    if (this.isFavorite(product.id)) {
      console.log('⚠️ Már kedvenc:', product.id);
      return of({ success: false, message: 'A termék már a kedvencek között van!' });
    }

    // Új kedvenc létrehozása
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

    // Hozzáadás a listához
    const updatedFavorites = [...currentFavorites, newFavorite];
    this.favoritesSubject.next(updatedFavorites);
    this.saveToLocalStorage();

    console.log('❤️ Kedvencekhez adva:', newFavorite.name);
    return of({ success: true, message: 'Termék hozzáadva a kedvencekhez!' });
  }

  // Kedvenc eltávolítása
  removeFavorite(productId: number): Observable<{ success: boolean; message: string }> {
    const currentFavorites = this.favoritesSubject.value;
    const updatedFavorites = currentFavorites.filter(f => f.id !== productId);
    
    if (updatedFavorites.length === currentFavorites.length) {
      return of({ success: false, message: 'A termék nem található a kedvencek között!' });
    }

    this.favoritesSubject.next(updatedFavorites);
    this.saveToLocalStorage();

    console.log('💔 Kedvencekből törölve:', productId);
    return of({ success: true, message: 'Termék eltávolítva a kedvencekből!' });
  }

  // Kedvenc állapot váltása
  toggleFavorite(product: any): Observable<{ success: boolean; message: string; isFavorite: boolean }> {
    if (this.isFavorite(product.id)) {
      this.removeFavorite(product.id).subscribe();
      return of({ success: true, message: 'Eltávolítva a kedvencekből!', isFavorite: false });
    } else {
      this.addFavorite(product).subscribe();
      return of({ success: true, message: 'Hozzáadva a kedvencekhez!', isFavorite: true });
    }
  }

  // Ellenőrzés: kedvenc-e
  isFavorite(productId: number): boolean {
    return this.favoritesSubject.value.some(f => f.id === productId);
  }

  // Kedvencek száma
  getFavoriteCount(): number {
    return this.favoritesSubject.value.length;
  }

  // Kedvencek törlése (kijelentkezéskor)
  clearFavorites(): void {
    this.favoritesSubject.next([]);
    localStorage.removeItem(this.STORAGE_KEY);
    console.log('🗑️ Kedvencek törölve');
  }

  // Frissítés
  refresh(): void {
    this.loadFromLocalStorage();
  }
}