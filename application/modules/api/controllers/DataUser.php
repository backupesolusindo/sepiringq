<?php
defined('BASEPATH') or exit('No direct script access allowed');

class DataUser extends REST_Controller
{

    public function __construct()
    {
        parent::__construct();
        $this->load->model("ModelAuth");
    }
    public function DataUser_get()
    {
        $id_user = $this->input->get("id_user");

        if ($id_user !== null) {
            $user = $this->db->get_where("user", array('id_user' => $id_user));
        } else {
            $user = $this->db->get("user");
        }
        // $user = $this->db->get_where("user", array('id_user' => $id_user));
        // if ($user->num_rows() > 0) {
        //     $data = $user->row_array();
        //     $message = array(
        //         'status' => 200,
        //         'message' => "OK",
        //         'count'   => $user->num_rows(),
        //     );
        // } else {
        //     $data = null;
        //     $message = array(
        //         'status' => 204,
        //         'message' => "NO_CONTENT"
        //     );
        if ($user->num_rows() > 0) {
            $data = $user->result_array();
            $message = array(
                'status' => 200,
                'message' => "OK",
                'count'   => count($data),
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
