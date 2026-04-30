import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, forkJoin, of } from 'rxjs';
import { map, catchError } from 'rxjs/operators';

@Injectable({
  providedIn: 'root'
})
export class ProductImageService {
  private apiUrl = 'http://127.0.0.1:8080/coreTech3-1.0-SNAPSHOT/webresources/products';
  private maxImages = 10;

  constructor(private http: HttpClient) {}

  getProductImages(productId: number): Observable<string[]> {
    console.log('Fetching images for product:', productId);
    
    const imageUrls: string[] = [];
    for (let i = 1; i <= this.maxImages; i++) {
      imageUrls.push(`${this.apiUrl}/${productId}/images/${i}`);
    }

    const requests = imageUrls.map(url => 
      this.http.get(url, { responseType: 'blob' }).pipe(
        map(() => {
          console.log('Image found:', url);
          return url;
        }),
        catchError(() => of(null))
      )
    );

    return forkJoin(requests).pipe(
      map(results => {
        const validUrls = results.filter((url): url is string => url !== null);
        console.log('Valid images:', validUrls);
        return validUrls;
      }),
      catchError(error => {
        console.error('Error:', error);
        return of([]);
      })
    );
  }
}