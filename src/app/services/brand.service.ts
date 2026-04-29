import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export interface Brand {
  id: number;
  name: string;
  description: string;
  logo_url: string;
}

interface BrandsResponse {
  status: string;
  statusCode: number;
  brands: any[];
  count: number;
}

@Injectable({
  providedIn: 'root'
})
export class BrandService {
  private apiUrl = 'http://127.0.0.1:8080/coreTech3-1.0-SNAPSHOT/webresources/brands';
  private http = inject(HttpClient);

  private logoMap: { [key: string]: string } = {
    'amd':            'assets/amd.png',
    'asus':           'assets/asus.png',
    'attack shark':   'assets/attack_shark.png',
    'corsair':        'assets/corsair.png',
    'dell':           'assets/dell.png',
    'finalmouse':     'assets/finalmouse.png',
    'gigabyte':       'assets/gigabyte.png',
    'intel':          'assets/intel.png',
    'logitech':       'assets/logitech.png',
    'msi':            'assets/msi.png',
    'noctua':         'assets/noctua.png',
    'nvidia':         'assets/nvidia.png',
    'nzxt':           'assets/nzxt.png',
    'razer':          'assets/razer.png',
    'samson':         'assets/samson.png',
    'samsung':        'assets/samsung.png',
    'steelseries':    'assets/steelseries.png',
    'western digital':'assets/western_digital.png',
  };

  headers = {
    headers: new HttpHeaders({
      'Content-Type': 'application/json',
    })
  };

  getAllBrands(): Observable<Brand[]> {
    return this.http.get<BrandsResponse>(`${this.apiUrl}`, this.headers).pipe(
      map(response => {
        if (response.status === 'Success' && response.brands) {
          return response.brands.map(b => ({
            id: b.id,
            name: b.name,
            description: b.description,
            logo_url: this.logoMap[b.name.toLowerCase()] || 'assets/brands/placeholder.png'
          }));
        }
        return [];
      })
    );
  }
}