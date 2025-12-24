<?php
defined('BASEPATH') or exit('No direct script access allowed');

class Konsumsi extends REST_Controller
{

    public function __construct()
    {
        parent::__construct();
        // $this->load->model("ModelAuth");
    }

    public function joinkonsum($id_user){
        $this->db->select('nama_makanan');
        $this->db->from('bahan_makanan');
        $this->db->join('konsumsi_detail', 'bahan_makanan.id_makanan = konsumsi_detail.id_makanan');
        $this->db->join('konsumsi', 'konsumsi_detail.id_konsumsi = konsumsi.idkonsumsi');
        
        $this->db->where('konsumsi.user_id_user', $id_user);
        // Execute the query and get the result
    $query = $this->db->get();
    
    // Check if there are rows in the result
    if ($query->num_rows() > 0) {
        // Return the result as an array of objects
        return $query->result();
    } else {
        // Return an empty array if no rows found
        return array();
    }
    }

    public function Konsumsi_post()
    {
        $id_user = $this->post("id_user");
        $total_kalori = $this->post("total_kalori");
        $keterangan = $this->post("keterangan");
        $kmakanan = $this->post("bahan_makanan_nama_makanan");

        
            $data = array(
                'waktu' => date("Y-m-d"),
                'create_on' => date("Y-m-d H:i:s"),
                'total_kalori' => $total_kalori,
                'keterangan' => $keterangan,
                'user_id_user' => $id_user, // Menggunakan id_user dari tabel user
            );

            if ($this->db->insert('konsumsi', $data)) {
                $insert_id = $this->db->insert_id(); // Mendapatkan ID konsumsi yang baru saja dimasukkan
                
                $data2 = array(
                    'id_makanan' => $kmakanan,
                    'id_konsumsi' => $insert_id
                );
                if ($this->db->insert('konsumsi_detail', $data2)) {
                    $insert_id = $this->db->insert_id();
                    $response = array(
                        'field' => 'id konsumsi detail',
                        'message' => $insert_id
                    );
                } else {
                    $response = array(
                        'status' => 500,
                        'message' => "INTERNAL_SERVER_ERROR"
                    );
                }
                $result = $this->joinkonsum($id_user);
                $response = array(
                    'field' => 'id konsumsi',
                    'message' => $result
                );
            } else {
                $response = array(
                    'status' => 500,
                    'message' => "INTERNAL_SERVER_ERROR"
                );
            }

        $status_response = array(
            'status' => 200,
            'message' => "OK"
        );

        $final_response = array("response" => $response, "message" => $status_response);
        $this->response($final_response);
    }
}
