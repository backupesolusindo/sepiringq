<?php
defined('BASEPATH') or exit('No direct script access allowed');

class Tkalori extends REST_Controller
{

    public function __construct()
    {
        parent::__construct();
        $this->load->model("ModelAuth");
    }

    public function calculateTotalKaloriSum($data)
    {
        return array_sum(array_column($data, 'total_kalori'));
    }

    public function Tkalori_get()
    {
        $id_user = $this->input->get("id_user");
        $waktu = $this->input->get("waktu");
        
        $this->db->select('user_id_user, waktu, total_kalori');
        $this->db->from('konsumsi');
        $this->db->join('user', 'user.id_user = konsumsi.user_id_user');
        $this->db->where('konsumsi.user_id_user', $id_user);
        $this->db->where('DATE(konsumsi.waktu)', $waktu); // Assuming 'waktu' is a datetime column

        $konsumsi = $this->db->get();

        if ($konsumsi->num_rows() > 0) {
            $data = $konsumsi->result_array();
            $waktu_values = array_column($data, 'waktu'); // Extract 'waktu' values into an array
            
            // Calculate total_kalori sum using the separate function
            $total_kalori_sum = $this->calculateTotalKaloriSum($data);
            
            $message = array(
                'status' => 200,
                'message' => "OK",
                'count'   => $konsumsi->num_rows(),
                'total_kalori_sum' => $total_kalori_sum,
            );
        } else {
            $data = null;
            $message = array(
                'status' => 204,
                'message' => "NO_CONTENT"
            );
        }
        
        $this->response(array('response' => $data, 'message' => $message));
    }
}
